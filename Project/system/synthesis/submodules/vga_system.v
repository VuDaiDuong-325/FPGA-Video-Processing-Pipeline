// vga_system.v
module vga_system # (
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16
)(
    // Giao tiếp với Hệ thống Qsys (Clock & Reset)
    input  wire                   vga_sys_clk_i, // Xung clock hệ thống (50MHz)
    input  wire                   vga_sys_rst_i, // Tín hiệu reset (Active-High)
    
    // Giao tiếp Avalon-MM Master (Đọc từ SDRAM)
    output wire [ADDR_WIDTH-1:0]  amm_address_o,
    output wire                   amm_read_o,
    input  wire [DATA_WIDTH-1:0]  amm_readdata_i,
    input  wire                   amm_readdatavalid_i,
    input  wire                   amm_waitrequest_i,
    
    // Giao tiếp ngoại vi VGA phía ngoài (Conduit xuất sang Chip DAC)
	 input  wire 						 vga_bank_i,
    input  wire                   vga_clk_i,     // Xung nhịp VGA 25MHz
    output wire                   vga_hsync_o,
    output wire                   vga_vsync_o,
    output wire [4:0]             vga_r_o,       // Định dạng màu xuất 16-bit RGB 565
    output wire [5:0]             vga_g_o,       
    output wire [4:0]             vga_b_o,       
    output wire                   vga_blank_n_o,
    output wire                   vga_sync_n_o
);

    wire                    fifo_we_w;
    wire [DATA_WIDTH-1:0]   fifo_din_w;
    wire                    fifo_full_w;
    wire                    fifo_empty_w;
    wire [DATA_WIDTH-1:0]   fifo_dout_w;
    wire                    fifo_re_w;
    wire                    blank_n_w;
    
    // Chỉ đọc pixel từ FIFO khi VGA đang ở trong vùng hiển thị hình ảnh có nghĩa
    assign fifo_re_w = blank_n_w && !fifo_empty_w;

    // 1. Khởi tạo bộ đọc Avalon Master Reader
    avalon_mm_master_reader #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_vga_reader (
        .clk_i               (vga_sys_clk_i),
        .rst_i               (vga_sys_rst_i),
        .fifo_we_o           (fifo_we_w),
        .fifo_din_o          (fifo_din_w),
        .fifo_full_i         (fifo_full_w),
        .vga_vsync_i         (vga_vsync_o),
        .amm_address_o       (amm_address_o),
        .amm_read_o          (amm_read_o),
        .amm_readdata_i      (amm_readdata_i),
        .amm_readdatavalid_i (amm_readdatavalid_i),
        .amm_waitrequest_i   (amm_waitrequest_i),
		  .write_bank_i(vga_bank_i)
    );

    // 2. Tái sử dụng module DC_FIFO sẵn có trong thiết kế của bạn
    dc_fifo #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(11) // Dung lượng 2048 tầng, đồng bộ tốt giữa 50MHz và 25MHz
    ) u_vga_fifo (
        .wr_clk_i  (vga_sys_clk_i),
        .wr_rst_i  (vga_sys_rst_i),
        .we_i      (fifo_we_w),
        .din_i     (fifo_din_w),
        .full_o    (fifo_full_w),
        
        .rd_clk_i  (vga_clk_i),
        .rd_rst_i  (vga_sys_rst_i),
        .re_i      (fifo_re_w),
        .dout_o    (fifo_dout_w),
        .empty_o   (fifo_empty_w)
    );

    // 3. Khởi tạo bộ định thời tín hiệu màn hình VGA
    vga_controller u_vga_controller (
        .vga_clk  (vga_clk_i),
        .rst      (vga_sys_rst_i),
        .hsync    (vga_hsync_o),
        .vsync    (vga_vsync_o),
        .blank_n  (blank_n_w),
        .sync_n   (vga_sync_n_o),
        .pixel_x  (),
        .pixel_y  ()
    );

    assign vga_blank_n_o = blank_n_w;

    // Tách và gán pixel màu RGB từ FIFO ra chân output VGA
    assign vga_r_o = (blank_n_w) ? fifo_dout_w[15:11] : 5'd0;
    assign vga_g_o = (blank_n_w) ? fifo_dout_w[10:5]  : 6'd0;
    assign vga_b_o = (blank_n_w) ? fifo_dout_w[4:0]   : 5'd0;

endmodule