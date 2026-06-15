# 1. Khai báo xung nhịp đầu vào
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
create_clock -name CAM_PCLK -period 41.666 [get_ports {CAM_PCLK}]

# 2. Derive PLL - Quartus sẽ tự tạo các clock con: sys_pll|outclk_0, outclk_1, vga_pll|outclk_0...
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

# 3. RÀNG BUỘC QUAN TRỌNG: Xử lý các đường bất đồng bộ (CDC)
# Vì bạn đã dùng module đồng bộ (pulse_synchronizer), hãy báo cho Quartus biết 
# đây là các đường không cần ép timing chặt, giúp nó không báo lỗi giả.
set_false_path -from [get_clocks {CAM_PCLK}] -to [get_clocks {*sys_pll*|outclk_0*}]
set_false_path -from [get_clocks {*sys_pll*|outclk_0*}] -to [get_clocks {CAM_PCLK}]

# 4. Ràng buộc tín hiệu Reset (luôn luôn an toàn)
set_false_path -from [get_ports {KEY[0]}]

# 5. Ràng buộc các chân I/O không đồng bộ (như SW, nút bấm)
set_false_path -from [get_ports {SW[*]}]