// =========================================================================
// PROJECT: CAMERA OV7670 TO VGA DISPLAY VIA SDRAM ON DE1-SOC
// FILE NAME: doan_top.v
// DESCRIPTION: Full Top-level implementation containing Read/Write Paths,
//              Dual-Clock FIFOs, and Image Color Processing Pipeline.
// =========================================================================

module doan_top (
    // CLOCK & RESET
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,          // KEY[0] dùng làm Reset hệ thống
    input  wire [9:0]  SW,           // Switch chọn chế độ
	 output wire [9:0]  LEDR,			 // LED debug kit
    
    // SDRAM Pins (Chip ngoài trên board DE1-SoC)
    output wire [12:0] DRAM_ADDR,
    output wire [1:0]  DRAM_BA,
    output wire        DRAM_CAS_N,
    output wire        DRAM_CKE,
    output wire        DRAM_CLK,
    output wire        DRAM_CS_N,
    inout  wire [15:0] DRAM_DQ,
    output wire        DRAM_LDQM,
    output wire        DRAM_RAS_N,
    output wire        DRAM_UDQM,
    output wire        DRAM_WE_N,
    
    // CAMERA OV7670 Pins (Kết nối qua Header mở rộng GPIO)
    output wire        CAM_XCLK,     // XCLK cấp cho Camera
    input  wire        CAM_PCLK,     // Xung đồng bộ pixel từ camera
    input  wire        CAM_VSYNC,    // Xung đồng bộ mành (khung hình)
    input  wire        CAM_HREF,     // Xung đồng bộ dòng
    input  wire [7:0]  CAM_DATA,     // Dữ liệu pixel (8-bit)
    output wire        CAM_SCL,      // I2C/SCCB Clock
    inout  wire        CAM_SDA,      // I2C/SCCB Data
    
    // VGA Pins (Kết nối bộ DAC ADV7123 ra cổng DB15)
    output wire [9:0]  VGA_R,
    output wire [9:0]  VGA_G,
    output wire [9:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    // =========================================================================
    // KHAI BÁO DÂY TÍN HIỆU VÀ THANH GHI (ALL WIRE & REGISTER DECLARATIONS)
    // =========================================================================
    
    // 1. Hệ thống & Xung nhịp (Clock & Reset)
    wire        rst_n;
    wire        clk_25m_vga;
    wire        clk_50m_sys;
    wire        clk_24m_cam;
    wire        clk_50m_sdram;

    // 2. Tín hiệu điều khiển cấu hình Camera từ Nios II Bus (PIO)
    wire [3:0]  sys_mode;
    wire [7:0]  sys_threshold;
    wire        sccb_start;
    wire        sccb_done;

    // 3. Luồng ghi dữ liệu Camera & Đồng bộ VSYNC (Camera Capture Path)
    wire [15:0] cam_data_16bit;
    wire        cam_write_en;
    wire [15:0] sdram_wrdata;
    wire        sdram_rdempty;
    wire        sdram_wrreq;
    reg  [2:0]  vsync_sync_reg;
    wire        frame_done;

    // 4. Bộ điều khiển Ghi tầng đệm SDRAM (SDRAM Write DMA Master)
    wire [24:0] w_dma_addr;
    wire [15:0] w_dma_writedata;
    wire        w_dma_write;
    wire        w_dma_waitrequest;

    // 5. Bộ điều khiển Đọc dữ liệu SDRAM (SDRAM Read DMA Master)
    wire [24:0] r_dma_addr;
    wire        r_dma_read;
    wire [15:0] r_dma_readdata;
    wire        r_dma_readdatavalid;
    wire        r_dma_waitrequest;

    // 6. Luồng đọc và tích trữ đệm VGA FIFO (VGA Read Path)
    wire        vga_fifo_wrreq;
    wire [15:0] vga_fifo_wrdata;
    wire [10:0] vga_fifo_wrusedw;
    wire        vga_fifo_rdreq;
    wire [15:0] vga_fifo_q;
    wire        vga_fifo_rdempty;
    wire        vga_req;

    // 7. Bộ dồn kênh chia sẻ Bus Avalon Master (Arbiter Bridge)
    wire [24:0] qsys_avm_address;
    wire [15:0] qsys_avm_writedata;
    wire        qsys_avm_write;
    wire        qsys_avm_read;
    wire        dma_write_bridge_waitrequest;
    wire [15:0] dma_write_bridge_readdata;
    wire        dma_write_bridge_readdatavalid;

    // 8. Đường truyền xử lý ảnh mã màu (Image Pipeline & Color Space)
    wire [7:0]  w_y;
    wire [7:0]  w_cb;
    wire [7:0]  w_cr;
    wire [10:0] vga_x;
    wire [10:0] vga_y;
	 
	 wire [9:0]  final_vga_r;
    wire [9:0]  final_vga_g;
    wire [9:0]  final_vga_b;


    // =========================================================================
    // KHỐI LOGIC BỔ TRỢ & PHÉP GÁN ĐIỀU KHIỂN (LOGIC & ASSIGNMENTS)
    // =========================================================================
    
    // Gán mạch nạp Reset cứng và gán Clock ngoại vi
    assign rst_n    = KEY[0];
    assign CAM_XCLK = clk_24m_cam; 
    assign DRAM_CLK = clk_50m_sdram;

    // Mạch dịch bit phát hiện cạnh lên VSYNC tạo tín hiệu kết thúc Frame hình
    always @(posedge clk_50m_sys or negedge rst_n) begin
        if (!rst_n) vsync_sync_reg <= 3'b0;
        else        vsync_sync_reg <= {vsync_sync_reg[1:0], CAM_VSYNC};
    end
    assign frame_done = (vsync_sync_reg[2] == 1'b0 && vsync_sync_reg[1] == 1'b1);

    // Điều khiển nạp/xuất đồng bộ cho hai đầu FIFO ghi/đọc
    assign sdram_wrreq    = !sdram_rdempty && !w_dma_waitrequest;
    assign vga_fifo_rdreq = vga_req && (~vga_fifo_rdempty);

	 // =========================================================================
    // HỆ THỐNG DEBUG BẰNG ĐÈN LED (Phân tích nguyên nhân kẹt Pipeline)
    // =========================================================================
    
    // LED 0: Báo trạng thái VGA FIFO. Nếu SÁNG -> FIFO có dữ liệu (Mạch đọc thành công). Nếu TẮT -> FIFO rỗng (Chết mạch đọc).
    assign LEDR[0] = ~vga_fifo_rdempty; 
    
    // LED 1: Báo trạng thái Qsys Bus. Nếu SÁNG RỰC liên tục -> Qsys bị kẹt (Treo bus Waitrequest).
    assign LEDR[1] = r_dma_waitrequest;
    
    // LED 2: Báo lệnh Đọc SDRAM. Nếu SÁNG MỜ MỜ -> Khối Read Controller đang tích cực đòi data.
    assign LEDR[2] = r_dma_read;
    
    // LED 3: Báo Dữ liệu SDRAM trả về. Nếu SÁNG MỜ MỜ -> Qsys có nhả dữ liệu ảnh ra. Nếu TẮT ngóm -> Qsys im lặng.
    assign LEDR[3] = r_dma_readdatavalid;
    
    // LED 4: Báo Tín hiệu hiển thị vùng hợp lệ của Camera. Nếu TẮT -> Camera hỏng hoặc chưa cấu hình I2C xong (Không xuất pixel)
    assign LEDR[4] = CAM_HREF;

    // =========================================================================
    // KHỞI TẠO CÁC THỰC THỂ MODULE CON (MODULE INSTANTIATIONS)
    // =========================================================================

    // Khối PLL tạo xung nhịp hệ thống, camera và SDRAM
    sys_pll u_sys_pll (
        .refclk   (CLOCK_50),
        .rst      (~rst_n),
        .outclk_0 (clk_50m_sys),
        .outclk_1 (clk_24m_cam),
        .outclk_2 (clk_50m_sdram),
        .locked   ()
    );

    // Khối PLL tạo xung nhịp quét pixel hiển thị VGA 25MHz
    vga_pll u_vga_pll (
        .refclk   (CLOCK_50),
        .rst      (~rst_n),
        .outclk_0 (clk_25m_vga),
        .locked   ()
    );

    // [MỚI] Khối giao tiếp cấu hình SCCB/I2C khởi động Camera OV7670
    ov7670_config_sccb u_sccb (
        .iCLK        (clk_50m_sys),
        .iRST_N      (rst_n),
        .iSTART      (sccb_start),   // Kích hoạt từ thanh ghi PIO của Nios II
        .oSCLK       (CAM_SCL),      // Xuất tín hiệu ra chân vật lý CAM_SCL
        .oSDA        (CAM_SDA),      // Khớp bus dữ liệu song hướng CAM_SDA
        .config_done (sccb_done)     // Báo trạng thái hoàn thành ngược về CPU
    );

    // Khối thu thập dữ liệu pixel thô từ Camera chuyển thành Word 16-bit
    ov7670_capture u_capture (
        .pclk     (CAM_PCLK),
        .reset    (rst_n),
        .vsync    (CAM_VSYNC),
        .href     (CAM_HREF),
        .data_in  (CAM_DATA),
        .data_out (cam_data_16bit),
        .write_en (cam_write_en)
    );

    // DCFIFO chuyển đổi vùng nhịp từ Clock Camera sang Clock Hệ thống 50MHz
    video_dcfifo u_cam_fifo (
        .aclr    (~rst_n),
        .data    (cam_data_16bit),
        .wrclk   (CAM_PCLK),
        .wrreq   (cam_write_en),
        .rdclk   (clk_50m_sys),
        .rdreq   (sdram_wrreq),
        .q       (sdram_wrdata),
        .rdempty (sdram_rdempty),
        .wrfull  (),
        .wrusedw (),
        .rdusedw ()
    );

    // Bộ điều khiển ghi luân phiên hai phân vùng địa chỉ (Double Buffer) vào SDRAM
    sdram_double_buffer_controller u_sdram_double_buffer_controller (
        .clk              (clk_50m_sys),
        .rst_n            (rst_n),
        .cam_vsync        (CAM_VSYNC),
        .cam_pixel_valid  (sdram_wrreq),
        .cam_pixel_data   (sdram_wrdata),
        .avm_address      (w_dma_addr),
        .avm_writedata    (w_dma_writedata),
        .avm_write        (w_dma_write),
        .avm_waitrequest  (w_dma_waitrequest)
    );

    // Bộ Master đọc dữ liệu từ SDRAM nạp tuần tự về phía màn hình
    sdram_read_controller u_sdram_read_controller (
        .clk                (clk_50m_sys),
        .rst_n              (rst_n),
        .frame_done         (frame_done),
        .avm_address        (r_dma_addr),
        .avm_read           (r_dma_read),
        .avm_waitrequest    (r_dma_waitrequest),
        .avm_readdata       (r_dma_readdata),
        .avm_readdatavalid  (r_dma_readdatavalid),
        .fifo_wrreq         (vga_fifo_wrreq),
        .fifo_wrdata        (vga_fifo_wrdata),
        .fifo_wrusedw       (vga_fifo_wrusedw)
    );

    // DCFIFO trung chuyển đồng bộ dữ liệu từ Clock Hệ thống sang Clock VGA 25MHz
    video_dcfifo u_vga_fifo (
        .aclr    (~rst_n),
        .data    (vga_fifo_wrdata),
        .wrclk   (clk_50m_sys),
        .wrreq   (vga_fifo_wrreq),
        .wrusedw (vga_fifo_wrusedw),
        .wrfull  (),
        
        .rdclk   (clk_25m_vga),
        .rdreq   (vga_fifo_rdreq),
        .q       (vga_fifo_q),
        .rdempty (vga_fifo_rdempty),
        .rdusedw ()
    );

    // Bộ chuyển đổi cấu trúc lấy mẫu hạt màu từ YUV 4:2:2 sang YUV 4:4:4 đầy đủ
    YUV422_to_444 u_YUV422_to_444 (
        .iYCbCr  (vga_fifo_q),
        .i_valid (vga_fifo_rdreq),
        .oY      (w_y),
        .oCb     (w_cb),
        .oCr     (w_cr),
        .iX      (vga_x[9:0]),
        .iCLK    (clk_25m_vga),
        .iRST_N  (rst_n)
    );

	 // Khối xử lý ảnh tổng hợp (Bao gồm YUV, Grayscale và Mux)
    VGA_Image_Processor u_image_processor (
        .iCLK    (clk_25m_vga),
        .iRST_N  (rst_n),
        .iMode   (SW[1:0]),      // Chọn chế độ từ SW 0, 1
        
        .i_valid (vga_fifo_rdreq),
        .iY      (w_y),
        .iCb     (w_cb),
        .iCr     (w_cr),
        
        .oRed    (final_vga_r),  // Đưa ra dây kết nối VGA
        .oGreen  (final_vga_g),
        .oBlue   (final_vga_b)
    );

    // Thực thể Qsys Interconnect System (CPU Nios II, Avalon Bus & SDRAM IP Core)
    system u0 (
        .clk_clk                        (clk_50m_sys),
        .reset_reset_n                  (rst_n),
        
        // CỔNG ĐỌC SDRAM (Nối trực tiếp với mạch điều khiển đọc VGA)
        .sdram_read_bridge_address        ({r_dma_addr, 1'b0}),      // Địa chỉ từ bộ đọc VGA
        .sdram_read_bridge_read           (r_dma_read),              // Lệnh đọc từ bộ đọc VGA
        .sdram_read_bridge_waitrequest    (r_dma_waitrequest),       // Tín hiệu bận trả về bộ đọc VGA
        .sdram_read_bridge_readdata       (r_dma_readdata),          // Dữ liệu ảnh trả về bộ đọc VGA
        .sdram_read_bridge_readdatavalid  (r_dma_readdatavalid),     // Tín hiệu báo dữ liệu hợp lệ
		  
		  .sdram_read_bridge_burstcount     (1'b1),                    // Đọc từng ô nhớ đơn lẻ (Single word)
        .sdram_read_bridge_byteenable     (2'b11),                   // Kích hoạt đọc đủ cả 2 bytes (16-bit)
        .sdram_read_bridge_write          (1'b0),                    // Cổng đọc không dùng lệnh ghi
        .sdram_read_bridge_writedata      (16'd0),                   // Dữ liệu ghi gán bằng 0
        .sdram_read_bridge_debugaccess    (1'b0),                    // Không dùng chức năng debugaccess
        
        // CỔNG GHI SDRAM (Nối trực tiếp với mạch điều khiển ghi Camera)
        .sdram_write_bridge_address       ({w_dma_addr, 1'b0}),      // Địa chỉ từ bộ ghi Camera
        .sdram_write_bridge_write         (w_dma_write),             // Lệnh ghi từ bộ ghi Camera
        .sdram_write_bridge_writedata     (w_dma_writedata),         // Dữ liệu ảnh từ bộ ghi Camera
        .sdram_write_bridge_waitrequest   (w_dma_waitrequest),       // Tín hiệu bận trả về bộ ghi Camera
        .sdram_write_bridge_read          (1'b0),                    // Cổng ghi không dùng lệnh đọc -> gán cố định bằng 0
		  
		  .sdram_write_bridge_readdata      (),                        // Để trống cổng ra dữ liệu đọc
        .sdram_write_bridge_readdatavalid (),                        // Để trống cổng ra valid đọc
        .sdram_write_bridge_burstcount     (1'b1),                   // Ghi từng ô nhớ đơn lẻ (Single word)
        .sdram_write_bridge_byteenable     (2'b11),                  // Kích hoạt ghi đủ cả 2 bytes (16-bit)
        .sdram_write_bridge_debugaccess    (1'b0),                   // Không dùng chức năng debugaccess
        
        // Ánh xạ đường dây dẫn thẳng ra chân chip SDRAM hàn trên board mạch
        .new_sdram_controller_0_wire_addr (DRAM_ADDR),
        .new_sdram_controller_0_wire_ba   (DRAM_BA),
        .new_sdram_controller_0_wire_cas_n(DRAM_CAS_N),
        .new_sdram_controller_0_wire_cke  (DRAM_CKE),
        .new_sdram_controller_0_wire_cs_n (DRAM_CS_N),
        .new_sdram_controller_0_wire_dq   (DRAM_DQ),
        .new_sdram_controller_0_wire_ras_n(DRAM_RAS_N),
        .new_sdram_controller_0_wire_dqm  ({DRAM_UDQM, DRAM_LDQM}),
        .new_sdram_controller_0_wire_we_n (DRAM_WE_N),
        
        // Các đường PIO Bus trao đổi thông số với chương trình C-Code trên Nios II
        .pio_mode_export        (sys_mode),
        .pio_threshold_export   (sys_threshold),
        .pio_sccb_start_export  (sccb_start),
        .pio_sccb_done_export   (sccb_done),
		  .pio_sw_export          (SW)
    );

    // Bộ điều khiển sinh ma trận đồng bộ quét hình ảnh ra cổng VGA
    VGA_controller u_vga (
        .iCLK       (clk_25m_vga),
        .iRST_N     (rst_n),
		  
        .iRed       (final_vga_r),
        .iGreen     (final_vga_g),
        .iBlue      (final_vga_b),
        
        .oCurrent_X (vga_x),
        .oCurrent_Y (vga_y),
        .oAddress   (),
        .oRequest   (vga_req),
        
        // Kết nối thẳng tới các chân I/O vật lý của bộ DAC VGA trên DE1-SoC
        .oVGA_R     (VGA_R),
        .oVGA_G     (VGA_G),
        .oVGA_B     (VGA_B),
        .oVGA_HS    (VGA_HS),
        .oVGA_VS    (VGA_VS),
        .oVGA_SYNC  (VGA_SYNC_N),
        .oVGA_BLANK (VGA_BLANK_N),
        .oVGA_CLOCK (VGA_CLK)
    );

endmodule