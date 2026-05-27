
module system (
	cam_bank_export,
	cam_din_export,
	cam_fifo_export,
	cam_href_export,
	cam_pclk_export,
	cam_vsync_export,
	clk_clk,
	reset_reset_n,
	sdram_wire_addr,
	sdram_wire_ba,
	sdram_wire_cas_n,
	sdram_wire_cke,
	sdram_wire_cs_n,
	sdram_wire_dq,
	sdram_wire_dqm,
	sdram_wire_ras_n,
	sdram_wire_we_n,
	vga_b_export,
	vga_bank_export,
	vga_blank_n_export,
	vga_clk_export,
	vga_g_export,
	vga_hsync_export,
	vga_r_export,
	vga_sync_n_export,
	vga_vsync_export);	

	output		cam_bank_export;
	input	[7:0]	cam_din_export;
	output		cam_fifo_export;
	input		cam_href_export;
	input		cam_pclk_export;
	input		cam_vsync_export;
	input		clk_clk;
	input		reset_reset_n;
	output	[12:0]	sdram_wire_addr;
	output	[1:0]	sdram_wire_ba;
	output		sdram_wire_cas_n;
	output		sdram_wire_cke;
	output		sdram_wire_cs_n;
	inout	[15:0]	sdram_wire_dq;
	output	[1:0]	sdram_wire_dqm;
	output		sdram_wire_ras_n;
	output		sdram_wire_we_n;
	output	[4:0]	vga_b_export;
	input		vga_bank_export;
	output		vga_blank_n_export;
	input		vga_clk_export;
	output	[5:0]	vga_g_export;
	output		vga_hsync_export;
	output	[4:0]	vga_r_export;
	output		vga_sync_n_export;
	output		vga_vsync_export;
endmodule
