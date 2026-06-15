import os
import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

# Tự động tạo thư mục input và output nếu chưa có
os.makedirs("input", exist_ok=True)
os.makedirs("output", exist_ok=True)

# ── Đổi đường dẫn thành Local ────────────────────────────
# Bạn hãy tạo thư mục 'input' cùng cấp với file python này và bỏ ảnh vào đó.
INPUT_FILE_PNG   = "input\duongngu.jpg"     

OUTPUT_FILE_PNG  = "duongngu.bin"

TARGET_W, TARGET_H = 640, 480

# Kiểm tra nếu file input chưa tồn tại thì thông báo dừng để tránh crash
if not os.path.exists(INPUT_FILE_PNG):
    print(f"[ERROR] Không tìm thấy file: {INPUT_FILE_PNG}")
    print("👉 Hãy tạo thư mục 'input' và copy file 'pic1.png' vào đó trước khi chạy lại.")
    exit()

# ── 1. Load & resize ──────────────────────────────────────
img = Image.open(INPUT_FILE_PNG).convert("RGB")
original_size = (img.width, img.height)
img = img.resize((TARGET_W, TARGET_H), Image.LANCZOS)
arr_original = np.array(img, dtype=np.uint8)
print(f"[INFO] Original size : {original_size[0]}×{original_size[1]}")
print(f"[INFO] Resized to    : {TARGET_W}×{TARGET_H}")

# ── 2. RGB888 → RGB565 (little-endian) ───────────────────
arr = arr_original.astype(np.uint16)
r5 = (arr[:,:,0] >> 3) & 0x1F
g6 = (arr[:,:,1] >> 2) & 0x3F
b5 = (arr[:,:,2] >> 3) & 0x1F
rgb565 = (r5 << 11) | (g6 << 5) | b5

# ── 3. Ghi file .bin little-endian ───────────────────────
rgb565.astype('<u2').tofile(OUTPUT_FILE_PNG)
size = os.path.getsize(OUTPUT_FILE_PNG)
assert size == TARGET_W * TARGET_H * 2
print(f"[INFO] Output        : {OUTPUT_FILE_PNG}  ({size} bytes)")
print(" Conversion complete!")

# ── 4. Decode ngược lại (mô phỏng RGB565_Decoder.v) ──────
raw = np.fromfile(OUTPUT_FILE_PNG, dtype='<u2').reshape(TARGET_H, TARGET_W)

r5d = ((raw >> 11) & 0x1F).astype(np.uint16)
g6d = ((raw >>  5) & 0x3F).astype(np.uint16)
b5d = ( raw        & 0x1F).astype(np.uint16)

r10 = ((r5d << 5) | r5d).astype(np.float32) / 1023.0 * 255.0
g10 = ((g6d << 4) | (g6d >> 2)).astype(np.float32) / 1023.0 * 255.0
b10 = ((b5d << 5) | b5d).astype(np.float32) / 1023.0 * 255.0

arr_decoded = np.stack([r10, g10, b10], axis=2).clip(0, 255).astype(np.uint8)

# ── 5. Tính sai số ───────────────────────────────────────
diff       = arr_original.astype(np.int16) - arr_decoded.astype(np.int16)
mean_err   = np.mean(np.abs(diff))
max_err    = np.max(np.abs(diff))
psnr_mse   = np.mean(diff.astype(np.float32)**2)
psnr       = 10 * np.log10(255**2 / psnr_mse) if psnr_mse > 0 else float('inf')
print(f"[INFO] Mean |error|  : {mean_err:.2f} / 255")
print(f"[INFO] Max  |error|  : {max_err}")
print(f"[INFO] PSNR          : {psnr:.1f} dB  (>38dB = tốt)")

# ── 6. Preview ───────────────────────────────────────────
fig = plt.figure(figsize=(18, 10))
fig.patch.set_facecolor('#1a1a2e')
gs  = gridspec.GridSpec(2, 3, figure=fig,
                        hspace=0.35, wspace=0.08,
                        left=0.04, right=0.96, top=0.88, bottom=0.05)

fig.suptitle("RGB565 Conversion Preview  —  DE1-SoC VGA Pipeline",
             fontsize=15, fontweight='bold', color='white', y=0.96)

# Row 1
ax0 = fig.add_subplot(gs[0, 0])
ax0.imshow(arr_original)
ax0.set_title("① Original (resized 640×480)", color='#a8d8ea', fontsize=10, pad=6)
ax0.axis('off')

ax1 = fig.add_subplot(gs[0, 1])
ax1.imshow(arr_decoded)
ax1.set_title("② Decoded from .bin\n(mô phỏng RGB565_Decoder.v)", color='#a8d8ea', fontsize=10, pad=6)
ax1.axis('off')

ax2 = fig.add_subplot(gs[0, 2])
diff_vis = np.abs(diff).max(axis=2)
im = ax2.imshow(diff_vis, cmap='hot', vmin=0, vmax=16)
ax2.set_title("③ Error map (max channel per pixel)", color='#a8d8ea', fontsize=10, pad=6)
ax2.axis('off')
cbar = fig.colorbar(im, ax=ax2, fraction=0.03, pad=0.02)
cbar.ax.yaxis.set_tick_params(color='white')
plt.setp(cbar.ax.yaxis.get_ticklabels(), color='white', fontsize=8)

# Row 2
cy, cx = TARGET_H // 2, TARGET_W // 2
crop_h, crop_w = 200, 200
y0, y1 = cy - crop_h//2, cy + crop_h//2
x0, x1 = cx - crop_w//2, cx + crop_w//2

ax3 = fig.add_subplot(gs[1, 0])
ax3.imshow(arr_original[y0:y1, x0:x1])
ax3.set_title("① Crop trung tâm — Original", color='#ffeaa7', fontsize=9, pad=6)
ax3.axis('off')

ax4 = fig.add_subplot(gs[1, 1])
ax4.imshow(arr_decoded[y0:y1, x0:x1])
ax4.set_title("② Crop trung tâm — Decoded", color='#ffeaa7', fontsize=9, pad=6)
ax4.axis('off')

ax5 = fig.add_subplot(gs[1, 2])
colors = ['#ff6b6b', '#6bff8e', '#6bb5ff']
labels = ['Red', 'Green', 'Blue']
for ch, (col, lbl) in enumerate(zip(colors, labels)):
    ax5.hist(np.abs(diff[:,:,ch]).ravel(), bins=32, range=(0, 32),
             alpha=0.65, color=col, label=lbl, density=True)
ax5.set_facecolor('#0d0d1a')
ax5.set_title("④ Error distribution per channel", color='#ffeaa7', fontsize=9, pad=6)
ax5.set_xlabel("Absolute error (0–255)", color='white', fontsize=8)
ax5.set_ylabel("Density", color='white', fontsize=8)
ax5.tick_params(colors='white', labelsize=7)
for spine in ax5.spines.values():
    spine.set_edgecolor('#444')
ax5.legend(fontsize=8, framealpha=0.3, labelcolor='white')

stats_text = (f"Mean error: {mean_err:.2f}   Max error: {max_err}   "
              f"PSNR: {psnr:.1f} dB   Byte order: little-endian ✓")
fig.text(0.5, 0.01, stats_text, ha='center', fontsize=9,
         color='#aaaaaa', style='italic')

# Lưu ảnh preview về thư mục output local
OUTPUT_PREVIEW = "output/preview_rgb565.png"
plt.savefig(OUTPUT_PREVIEW, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
print(f" Preview saved: {OUTPUT_PREVIEW}")
plt.show() # Hiển thị cửa sổ biểu đồ ngay trên máy tính


# ── 7. Đoạn phân tích file Webp / Landscape ────────────────
print("\n" + "─"*50)
# Lưu ý: Sửa lại đường dẫn đọc file bin cho đúng với OUTPUT_FILE_WEBP hoặc OUTPUT_FILE_PNG của bạn.
# Ở đây tôi chuyển sang đọc thử file OUTPUT_FILE_PNG vừa tạo ở trên để tránh lỗi thiếu file landscape.
if os.path.exists(OUTPUT_FILE_PNG):
    print(f"[INFO] Analyzing generated binary file: {OUTPUT_FILE_PNG}")
    raw_analysis = np.fromfile(OUTPUT_FILE_PNG, dtype='<u2').reshape(480, 640)

    # In 5 pixel đầu tiên (góc top-left)
    for i in range(5):
        w = int(raw_analysis[0, i])
        r = ((w>>11)&0x1F)*8
        g = ((w>>5)&0x3F)*4
        b = (w&0x1F)*8
        print(f"Pixel[0,{i}]: word=0x{w:04X}  R={r:3d} G={g:3d} B={b:3d}")

    # In màu trung bình của từng vùng
    print(f"\nMean top-left 50x50:")
    region = raw_analysis[0:50, 0:50]
    r5 = ((region>>11)&0x1F)*8; g6=((region>>5)&0x3F)*4; b5=(region&0x1F)*8
    print(f"  R={r5.mean():.0f} G={g6.mean():.0f} B={b5.mean():.0f}")
else:
    print("[WARNING] Chưa có file binary để phân tích phân đoạn cuối.")