
module system (
	clk_clk,
	new_sdram_controller_0_wire_addr,
	new_sdram_controller_0_wire_ba,
	new_sdram_controller_0_wire_cas_n,
	new_sdram_controller_0_wire_cke,
	new_sdram_controller_0_wire_cs_n,
	new_sdram_controller_0_wire_dq,
	new_sdram_controller_0_wire_dqm,
	new_sdram_controller_0_wire_ras_n,
	new_sdram_controller_0_wire_we_n,
	pio_mode_export,
	pio_sw_export,
	pio_threshold_export,
	reset_reset_n,
	sdram_read_bridge_waitrequest,
	sdram_read_bridge_readdata,
	sdram_read_bridge_readdatavalid,
	sdram_read_bridge_burstcount,
	sdram_read_bridge_writedata,
	sdram_read_bridge_address,
	sdram_read_bridge_write,
	sdram_read_bridge_read,
	sdram_read_bridge_byteenable,
	sdram_read_bridge_debugaccess,
	sdram_write_bridge_waitrequest,
	sdram_write_bridge_readdata,
	sdram_write_bridge_readdatavalid,
	sdram_write_bridge_burstcount,
	sdram_write_bridge_writedata,
	sdram_write_bridge_address,
	sdram_write_bridge_write,
	sdram_write_bridge_read,
	sdram_write_bridge_byteenable,
	sdram_write_bridge_debugaccess,
	img_load_export);	

	input		clk_clk;
	output	[12:0]	new_sdram_controller_0_wire_addr;
	output	[1:0]	new_sdram_controller_0_wire_ba;
	output		new_sdram_controller_0_wire_cas_n;
	output		new_sdram_controller_0_wire_cke;
	output		new_sdram_controller_0_wire_cs_n;
	inout	[15:0]	new_sdram_controller_0_wire_dq;
	output	[1:0]	new_sdram_controller_0_wire_dqm;
	output		new_sdram_controller_0_wire_ras_n;
	output		new_sdram_controller_0_wire_we_n;
	output	[1:0]	pio_mode_export;
	input	[9:0]	pio_sw_export;
	output	[7:0]	pio_threshold_export;
	input		reset_reset_n;
	output		sdram_read_bridge_waitrequest;
	output	[15:0]	sdram_read_bridge_readdata;
	output		sdram_read_bridge_readdatavalid;
	input	[0:0]	sdram_read_bridge_burstcount;
	input	[15:0]	sdram_read_bridge_writedata;
	input	[25:0]	sdram_read_bridge_address;
	input		sdram_read_bridge_write;
	input		sdram_read_bridge_read;
	input	[1:0]	sdram_read_bridge_byteenable;
	input		sdram_read_bridge_debugaccess;
	output		sdram_write_bridge_waitrequest;
	output	[15:0]	sdram_write_bridge_readdata;
	output		sdram_write_bridge_readdatavalid;
	input	[0:0]	sdram_write_bridge_burstcount;
	input	[15:0]	sdram_write_bridge_writedata;
	input	[25:0]	sdram_write_bridge_address;
	input		sdram_write_bridge_write;
	input		sdram_write_bridge_read;
	input	[1:0]	sdram_write_bridge_byteenable;
	input		sdram_write_bridge_debugaccess;
	output		img_load_export;
endmodule
