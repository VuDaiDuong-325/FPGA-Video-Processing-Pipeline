// =========================================================================
// PROJECT: STATIC BIN IMAGE → VGA DISPLAY via SDRAM on DE1-SoC RevF
// FILE NAME: doan_top.v  
// =========================================================================

module doan_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [9:0]  LEDR,

    // SDRAM
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

    // VGA
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    // -------------------------------------------------------------------------
    // CLOCK & RESET
    // -------------------------------------------------------------------------
    wire rst_n;
    wire clk_25m_vga, clk_50m_sys, clk_50m_sdram;
    wire sys_pll_locked, vga_pll_locked;

    assign rst_n    = KEY[0] && sys_pll_locked && vga_pll_locked;
    assign DRAM_CLK = clk_50m_sdram;

    sys_pll u_sys_pll (
        .refclk   (CLOCK_50),
        .rst      (~KEY[0]),
        .outclk_0 (clk_50m_sys),
        .outclk_1 (clk_50m_sdram),
        .locked   (sys_pll_locked)
    );

    vga_pll u_vga_pll (
        .refclk   (CLOCK_50),
        .rst      (~KEY[0]),
        .outclk_0 (clk_25m_vga),
        .locked   (vga_pll_locked)
    );

    // -------------------------------------------------------------------------
    // PIO TỪ NIOS II
    // -------------------------------------------------------------------------
    wire [1:0]  sys_mode;
    wire        pio_img_loaded;

    // -------------------------------------------------------------------------
    // SDRAM DMA
    // -------------------------------------------------------------------------
    wire [24:0] r_dma_addr;
    wire        r_dma_read;
    wire [15:0] r_dma_readdata;
    wire        r_dma_readdatavalid;
    wire        r_dma_waitrequest;

    wire [24:0] w_dma_addr;
    wire [15:0] w_dma_writedata;
    wire        w_dma_write;
    wire        w_dma_waitrequest;

    // -------------------------------------------------------------------------
    // VGA DCFIFO (SHOWAHEAD=ON, 2048 words, 16-bit)
    // -------------------------------------------------------------------------
    wire        vga_fifo_wrreq, vga_fifo_wrfull;
    wire [15:0] vga_fifo_wrdata;
    wire [10:0] vga_fifo_wrusedw;
    wire        vga_fifo_rdreq;
    wire [15:0] vga_fifo_q;
    wire        vga_fifo_rdempty;
    wire        vga_req;

    wire        vga_frame_done;
    reg  [1:0]  fifo_clr_sync;   // 2-FF CDC sang clk_25m_vga
    reg         fifo_aclr;
    reg  [3:0]  fifo_clr_cnt;

    assign vga_fifo_rdreq = vga_req && (~vga_fifo_rdempty) && (~fifo_aclr);

    // -------------------------------------------------------------------------
    // VGA FRAME DONE: rising edge VGA_VS (kết thúc vsync, safe để reset)
    // -------------------------------------------------------------------------
    reg [1:0] vs_sync;
    always @(posedge clk_50m_sys or negedge rst_n) begin
<<<<<<< Updated upstream
        if (!rst_n) vsync_sync_reg <= 3'b0;
        else        vsync_sync_reg <= {vsync_sync_reg[1:0], CAM_VSYNC};
    end
    assign frame_done = (vsync_sync_reg[2] == 1'b0 && vsync_sync_reg[1] == 1'b1);
=======
        if (!rst_n) vs_sync <= 2'b11;
        else        vs_sync <= {vs_sync[0], VGA_VS};
    end
    // Rising edge (0→1): VGA_VS trở về HIGH = kết thúc vsync interval
    assign vga_frame_done = (~vs_sync[1]) && vs_sync[0];

    always @(posedge clk_25m_vga or negedge rst_n) begin
        if (!rst_n) begin
            fifo_clr_sync <= 2'b0;
            fifo_aclr     <= 1'b1;
            fifo_clr_cnt  <= 4'd0;
        end else begin
            fifo_clr_sync <= {fifo_clr_sync[0], vga_frame_done};
>>>>>>> Stashed changes

            if (fifo_clr_sync[1] && ~fifo_clr_sync[0]) begin
                // Rising edge (sau CDC): bắt đầu flush
                fifo_aclr    <= 1'b1;
                fifo_clr_cnt <= 4'd8;
            end else if (fifo_clr_cnt != 4'd0) begin
                fifo_clr_cnt <= fifo_clr_cnt - 1'b1;
                fifo_aclr    <= 1'b1;
            end else begin
                fifo_aclr <= 1'b0;
            end
        end
    end

<<<<<<< Updated upstream
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
=======
    // -------------------------------------------------------------------------
    // SDRAM READ CONTROLLER
    // -------------------------------------------------------------------------
    sdram_read_controller u_sdram_read_controller (
        .clk               (clk_50m_sys),
        .rst_n             (rst_n),
        .cam_frame_done    (pio_img_loaded),
        .vga_frame_done    (vga_frame_done),
        .cam_write_buffer  (1'b0),
        .avm_address       (r_dma_addr),
        .avm_read          (r_dma_read),
        .avm_waitrequest   (r_dma_waitrequest),
        .avm_readdata      (r_dma_readdata),
        .avm_readdatavalid (r_dma_readdatavalid),
        .fifo_wrreq        (vga_fifo_wrreq),
        .fifo_wrdata       (vga_fifo_wrdata),
        .fifo_wrusedw      (vga_fifo_wrusedw)
>>>>>>> Stashed changes
    );

    // -------------------------------------------------------------------------
    // DCFIFO: clk_50m_sys (write) → clk_25m_vga (read)
    // -------------------------------------------------------------------------
    video_dcfifo u_vga_fifo (
<<<<<<< Updated upstream
        .aclr    (~rst_n),
=======
        .aclr    (~rst_n | fifo_aclr),
>>>>>>> Stashed changes
        .data    (vga_fifo_wrdata),
        .wrclk   (clk_50m_sys),
        .wrreq   (vga_fifo_wrreq),
        .wrusedw (vga_fifo_wrusedw),
        .wrfull  (vga_fifo_wrfull),
        .rdclk   (clk_25m_vga),
        .rdreq   (vga_fifo_rdreq),
        .q       (vga_fifo_q),
        .rdempty (vga_fifo_rdempty),
        .rdusedw ()
    );

    // -------------------------------------------------------------------------
    // RGB565 DECODER - Stage 1 của data pipeline
    // -------------------------------------------------------------------------
    wire [9:0] rgb_r, rgb_g, rgb_b;
    wire       rgb_valid;

    RGB565_Decoder #(.SWAP_BYTES(0)) u_rgb565_dec (
        .iCLK    (clk_25m_vga),
        .iRST_N  (rst_n),
        .i_valid (vga_fifo_rdreq),
        .iRGB565 (vga_fifo_q),
        .oRed    (rgb_r),
        .oGreen  (rgb_g),
        .oBlue   (rgb_b),
        .o_valid (rgb_valid)
    );

    // -------------------------------------------------------------------------
    // IMAGE PROCESSOR - Stage 2 của data pipeline
    // -------------------------------------------------------------------------
    wire [9:0] final_vga_r, final_vga_g, final_vga_b;
    wire [10:0] vga_x, vga_y;

    VGA_Image_Processor u_image_processor (
        .iCLK    (clk_25m_vga),
        .iRST_N  (rst_n),
        .iMode   (SW[1:0]),
        .i_valid (rgb_valid),
        .iRed    (rgb_r),
        .iGreen  (rgb_g),
        .iBlue   (rgb_b),
        .oRed    (final_vga_r),
        .oGreen  (final_vga_g),
        .oBlue   (final_vga_b)
    );

    // -------------------------------------------------------------------------
    // QSYS SYSTEM (Nios II + SDRAM controller + PIO)
    // -------------------------------------------------------------------------
    system u0 (
<<<<<<< Updated upstream
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
=======
        .clk_clk           (clk_50m_sys),
        .reset_reset_n     (rst_n),

        // SDRAM read port (byte address: {word_addr, 1'b0})
        .sdram_read_bridge_address        ({r_dma_addr, 1'b0}),
        .sdram_read_bridge_read           (r_dma_read),
        .sdram_read_bridge_waitrequest    (r_dma_waitrequest),
        .sdram_read_bridge_readdata       (r_dma_readdata),
        .sdram_read_bridge_readdatavalid  (r_dma_readdatavalid),
        .sdram_read_bridge_burstcount     (1'b1),
        .sdram_read_bridge_byteenable     (2'b11),
        .sdram_read_bridge_write          (1'b0),
        .sdram_read_bridge_writedata      (16'd0),
        .sdram_read_bridge_debugaccess    (1'b0),

        // SDRAM write port (Nios II ghi ảnh)
        .sdram_write_bridge_address       ({w_dma_addr, 1'b0}),
        .sdram_write_bridge_write         (w_dma_write),
        .sdram_write_bridge_writedata     (w_dma_writedata),
        .sdram_write_bridge_waitrequest   (w_dma_waitrequest),
        .sdram_write_bridge_read          (1'b0),
        .sdram_write_bridge_readdata      (),
        .sdram_write_bridge_readdatavalid (),
        .sdram_write_bridge_burstcount    (1'b1),
        .sdram_write_bridge_byteenable    (2'b11),
        .sdram_write_bridge_debugaccess   (1'b0),

        // SDRAM chip
        .new_sdram_controller_0_wire_addr  (DRAM_ADDR),
        .new_sdram_controller_0_wire_ba    (DRAM_BA),
        .new_sdram_controller_0_wire_cas_n (DRAM_CAS_N),
        .new_sdram_controller_0_wire_cke   (DRAM_CKE),
        .new_sdram_controller_0_wire_cs_n  (DRAM_CS_N),
        .new_sdram_controller_0_wire_dq    (DRAM_DQ),
        .new_sdram_controller_0_wire_ras_n (DRAM_RAS_N),
        .new_sdram_controller_0_wire_dqm   ({DRAM_UDQM, DRAM_LDQM}),
        .new_sdram_controller_0_wire_we_n  (DRAM_WE_N),

        // PIO
        .pio_mode_export      (sys_mode),
        .img_load_export      (pio_img_loaded),
        .pio_sw_export        (SW)
>>>>>>> Stashed changes
    );

    // -------------------------------------------------------------------------
    // VGA CONTROLLER - Stage 3 của data pipeline
    // -------------------------------------------------------------------------
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
        .oVGA_R     (VGA_R),
        .oVGA_G     (VGA_G),
        .oVGA_B     (VGA_B),
        .oVGA_HS    (VGA_HS),
        .oVGA_VS    (VGA_VS),
        .oVGA_SYNC  (VGA_SYNC_N),
        .oVGA_BLANK (VGA_BLANK_N),
        .oVGA_CLOCK (VGA_CLK)
    );
	 

    // -------------------------------------------------------------------------
    // LED DEBUG
    // -------------------------------------------------------------------------
    assign LEDR[0] = ~vga_fifo_rdempty;    // FIFO có data
    assign LEDR[1] = r_dma_waitrequest;    // SDRAM busy
    assign LEDR[2] = r_dma_read;           // DMA đang đọc
    assign LEDR[3] = r_dma_readdatavalid;  // Data valid từ SDRAM
    assign LEDR[4] = pio_img_loaded;       // Nios II đã tải ảnh
    assign LEDR[5] = vga_frame_done;       // Frame sync pulse
    assign LEDR[6] = fifo_aclr;            // FIFO đang được flush
    assign LEDR[7] = vga_fifo_wrfull;      // FIFO write full (overflow cảnh báo)
    assign LEDR[9:8] = 2'b0;

endmodule