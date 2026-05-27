// ========================================================================
// soc_camera.v  — Top-level wrapper for DE1-SoC
// Đã tối ưu hóa hệ thống Clock bằng sys_pll và pll_25mhz
// ========================================================================

module soc_camera (
    // -------------------------------------------------------
    // 1. Board clocks & buttons
    // -------------------------------------------------------
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,          // KEY[0] = active-low reset

    // -------------------------------------------------------
    // 2. Camera OV7670 (GPIO header)
    // -------------------------------------------------------
    input  wire        CAM_PCLK,
    input  wire        CAM_VSYNC,
    input  wire        CAM_HREF,
    input  wire [7:0]  CAM_DIN,
    output wire        CAM_XCLK,     
    output wire        CAM_SIOC,     
    inout  wire        CAM_SIOD,     

    // -------------------------------------------------------
    // 3. Status LED
    // -------------------------------------------------------
    output wire [0:0]  LEDR,         // LEDR[0] = FIFO-full warning

    // -------------------------------------------------------
    // 4. SDRAM (IS42S16320B on DE1-SoC)
    // -------------------------------------------------------
    output wire [12:0] DRAM_ADDR,
    output wire [1:0]  DRAM_BA,
    output wire        DRAM_CAS_N,
    output wire        DRAM_CKE,
    output wire        DRAM_CLK,     // Xung nhịp lệch pha -3ns cấp cho chip RAM ngoài board
    output wire        DRAM_CS_N,
    inout  wire [15:0] DRAM_DQ,
    output wire [1:0]  DRAM_DQM,
    output wire        DRAM_RAS_N,
    output wire        DRAM_WE_N,

    // -------------------------------------------------------
    // 5. VGA (via DE1-SoC 15-pin D-Sub, 4 bits per channel)
    // -------------------------------------------------------
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK       // 25 MHz pixel clock chuẩn cấp ra ngoài cổng VGA
);

    // -------------------------------------------------------
    // Internal Wires for Clock Systems
    // -------------------------------------------------------
    wire        clk_sys_50mhz;       // Xung hệ thống ổn định từ PLL (0 ns phase)
    wire        clk_sdram_phase_w;   // Xung chạy sớm 3ns (-3000 ps phase shift)
    wire        vga_clk_w;           // Xung 25 MHz sạch từ PLL dành cho VGA và Camera

    wire        rst_n_w  = KEY[0];   // active-low từ nút nhấn
    wire        rst_h_w  = ~KEY[0];  // active-high nếu cần

    // Full-resolution VGA colour bus từ Qsys
    wire [4:0]  vga_r5_w;
    wire [5:0]  vga_g6_w;
    wire [4:0]  vga_b5_w;
    wire        vga_blank_n_w;
    wire        vga_sync_n_w;
    wire        vga_hs_w;
    wire        vga_vs_w;
	 wire 		 ping_pong_bank_w;

    // -------------------------------------------------------
    // 1. Khối PLL Hệ Thống (sys_pll)
    // Cung cấp xung 50MHz sạch cho Nios II và xung lệch pha cho SDRAM
    // -------------------------------------------------------
    sys_pll u_sys_pll (
        .refclk   (CLOCK_50),          // Xung gốc 50MHz thạch anh trên board
        .rst      (1'b0),              
        .outclk_0 (clk_sys_50mhz),     // Output 0: 50 MHz, Phase shift = 0 ps (Nuôi hệ thống)
        .outclk_1 (clk_sdram_phase_w)  // Output 1: 50 MHz, Phase shift = -3000 ps (Nuôi SDRAM)
    );

    // Cấp xung dịch pha ra chân cứng của chip SDRAM bên ngoài
    assign DRAM_CLK = clk_sdram_phase_w;

    // -------------------------------------------------------
    // 2. Khối PLL Video & Camera (pll_25mhz)
    // Thay thế hoàn toàn cho mạch chia tần bằng thanh ghi cũ và pll_24mhz cũ
    // -------------------------------------------------------
    pll_25mhz u_pll_25mhz (
        .refclk   (CLOCK_50),
        .rst      (1'b0),
        .outclk_0 (vga_clk_w)          // Output 0: 25 MHz sạch chuẩn toàn cục (Global Clock)
    );

    // Chia sẻ xung 25MHz này làm Master Clock (XCLK) cấp trực tiếp cho Camera
    assign CAM_XCLK = vga_clk_w;   

    // -------------------------------------------------------
    // Khối cấu hình khởi tạo cho Camera OV7670 qua SCCB
    // -------------------------------------------------------
    ov7670_config u_ov7670_config (
        .clk_i    (clk_sys_50mhz),     // Sử dụng xung hệ thống ổn định từ PLL thay vì CLOCK_50 trực tiếp
        .rst_n_i  (rst_n_w),
        .sioc_o   (CAM_SIOC),
        .siod_io  (CAM_SIOD),
        .done_o   ()           
    );

    // -------------------------------------------------------
    // Hệ thống Qsys (Bao gồm Nios II, SDRAM, Camera, và VGA)
    // -------------------------------------------------------
    system u_system (
        // Clock & Reset hệ thống nuôi CPU và các IP bên trong Qsys
        .clk_clk                    (clk_sys_50mhz), 
        .reset_reset_n              (KEY[0]),

        // Conduits kết nối trực tiếp tới Camera vật lý
        .cam_pclk_export            (CAM_PCLK),
        .cam_vsync_export           (CAM_VSYNC),
        .cam_href_export            (CAM_HREF),
        .cam_din_export             (CAM_DIN),
        .cam_fifo_export            (LEDR[0]),
		  .cam_bank_export				(ping_pong_ram_w),

        // Các đường dây vật lý nối tới chân chip SDRAM
        .sdram_wire_addr            (DRAM_ADDR),
        .sdram_wire_ba              (DRAM_BA),
        .sdram_wire_cas_n           (DRAM_CAS_N),
        .sdram_wire_cke             (DRAM_CKE),
        .sdram_wire_cs_n            (DRAM_CS_N),
        .sdram_wire_dq              (DRAM_DQ),
        .sdram_wire_dqm             (DRAM_DQM),
        .sdram_wire_ras_n           (DRAM_RAS_N),
        .sdram_wire_we_n            (DRAM_WE_N),

        // Conduits kết nối tới VGA nhận từ bộ sinh hình ảnh Qsys
        .vga_clk_export             (vga_clk_w),
        .vga_hsync_export           (vga_hs_w),
        .vga_vsync_export           (vga_vs_w),
        .vga_r_export               (vga_r5_w),
        .vga_g_export               (vga_g6_w),
        .vga_b_export               (vga_b5_w),
        .vga_blank_n_export         (vga_blank_n_w),
        .vga_sync_n_export          (vga_sync_n_w),
		  .vga_bank_export				(ping_pong_ram_w)
    );

    // -------------------------------------------------------
    // Áp xạ tín hiệu màu từ RGB565 (16-bit) -> 4-bit mỗi kênh của DE1-SoC
    // Bằng cách lấy các bit cao nhất (MSB) của mỗi kênh màu
    // -------------------------------------------------------
    assign VGA_HS      = vga_hs_w;
    assign VGA_VS      = vga_vs_w;
    assign VGA_BLANK_N = vga_blank_n_w;
    assign VGA_SYNC_N  = vga_sync_n_w;
    assign VGA_CLK     = vga_clk_w;       // Cấp xung 25MHz chuẩn từ PLL ra bộ chuyển đổi DAC trên board
    assign VGA_R       = vga_r5_w[4:1];   // Lấy 4 bit cao của 5-bit Red
    assign VGA_G       = vga_g6_w[5:2];   // Lấy 4 bit cao của 6-bit Green
    assign VGA_B       = vga_b5_w[4:1];   // Lấy 4 bit cao của 5-bit Blue
     
endmodule