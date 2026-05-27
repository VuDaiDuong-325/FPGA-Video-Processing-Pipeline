// camera_system.v
// Fixes applied:
//   CDC BUG: cam_vsync_i is in the camera pclk domain, but
//   avalon_mm_master_writer runs on csi_clk_i (system 50 MHz).
//   A 2-stage synchronizer is now inserted so the writer only
//   sees a metastability-free version of VSYNC.

module camera_system #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16
)(
    // =====================================================
    // 1. System interface (Qsys)
    // =====================================================
    input  wire                   csi_clk_i,
    input  wire                   csi_rst_i,
    output wire                   fifo_full_warning_o,

    // =====================================================
    // 2. Avalon-MM Master (write to SDRAM)
    // =====================================================
    output wire [ADDR_WIDTH-1:0]  amm_address_o,
    output wire                   amm_write_o,
    output wire [DATA_WIDTH-1:0]  amm_writedata_o,
    input  wire                   amm_waitrequest_i,

    // =====================================================
    // 3. Camera OV7670 signals (conduit)
    // =====================================================
    input  wire                   cam_pclk_i,
    input  wire                   cam_vsync_i,
    input  wire                   cam_href_i,
    input  wire [7:0]             cam_din_i,
	 output wire 						 cam_bank_o
);

    // Internal wires
    wire [15:0] pixel_data_w;
    wire        pixel_valid_w;
    wire        fifo_empty_w;
    wire [15:0] fifo_dout_w;
    wire        fifo_re_w;
    wire        fifo_full_w;

    assign fifo_full_warning_o = fifo_full_w;

    // ----------------------------------------------------------
    // CDC FIX: synchronise cam_vsync_i into the system clock
    // domain before passing to the Avalon writer.
    // cam_vsync_i is driven by the camera's PCLK (up to 24 MHz),
    // while the writer runs on csi_clk_i (50 MHz).
    // ----------------------------------------------------------
    reg cam_vsync_d1_r, cam_vsync_d2_r;
    wire cam_vsync_sync_w = cam_vsync_d2_r;   // 2-FF synchronised signal

    always @(posedge csi_clk_i) begin
        if (csi_rst_i) begin
            cam_vsync_d1_r <= 1'b0;
            cam_vsync_d2_r <= 1'b0;
        end else begin
            cam_vsync_d1_r <= cam_vsync_i;
            cam_vsync_d2_r <= cam_vsync_d1_r;
        end
    end

    // ----------------------------------------------------------
    // 1. Pixel capture (runs in pclk domain)
    // ----------------------------------------------------------
    camera_capture u_camera_capture (
        .pclk_i        (cam_pclk_i),
        .rst_n_i       (~csi_rst_i),
        .vsync_i       (cam_vsync_i),
        .href_i        (cam_href_i),
        .din_i         (cam_din_i),
        .pixel_data_o  (pixel_data_w),
        .pixel_valid_o (pixel_valid_w)
    );

    // ----------------------------------------------------------
    // 2. DC-FIFO: crosses from pclk domain to system clock domain
    //    Depth 2048 entries × 16-bit = 4 kB — enough to absorb
    //    one full line (640 pixels × 2 bytes) with margin.
    // ----------------------------------------------------------
    dc_fifo #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(11)
    ) u_fifo (
        .wr_clk_i  (cam_pclk_i),
        .wr_rst_i  (csi_rst_i),
        .we_i      (pixel_valid_w),
        .din_i     (pixel_data_w),
        .full_o    (fifo_full_w),

        .rd_clk_i  (csi_clk_i),
        .rd_rst_i  (csi_rst_i),
        .re_i      (fifo_re_w),
        .dout_o    (fifo_dout_w),
        .empty_o   (fifo_empty_w)
    );

    // ----------------------------------------------------------
    // 3. Avalon master writer (runs in system clock domain)
    //    VSYNC is now the synchronised version — CDC fix applied.
    // ----------------------------------------------------------
    avalon_mm_master_writer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_master (
        .clk_i             (csi_clk_i),
        .rst_i             (csi_rst_i),

        .fifo_empty_i      (fifo_empty_w),
        .fifo_dout_i       (fifo_dout_w),
        .fifo_re_o         (fifo_re_w),
        .vsync_i           (cam_vsync_sync_w),   // FIX: use synced signal

        .amm_address_o     (amm_address_o),
        .amm_write_o       (amm_write_o),
        .amm_writedata_o   (amm_writedata_o),
        .amm_waitrequest_i (amm_waitrequest_i),
		  .write_bank_o		(cam_bank_o)
    );

endmodule