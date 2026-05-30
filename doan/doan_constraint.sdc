# 1. Khai báo xung nhịp đầu vào từ thạch anh trên Kit (50 MHz = chu kỳ 20ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# 2. Khai báo xung nhịp đầu vào từ Camera OV7670 (VD: 24 MHz = chu kỳ ~41.666ns)
create_clock -name CAM_PCLK -period 41.666 [get_ports {CAM_PCLK}]

# 3. Yêu cầu Quartus TỰ ĐỘNG suy luận các tần số đầu ra của toàn bộ PLL
derive_pll_clocks -create_base_clocks

# 4. Tự động tính toán độ rung pha (jitter) để phân tích đường truyền an toàn hơn
derive_clock_uncertainty