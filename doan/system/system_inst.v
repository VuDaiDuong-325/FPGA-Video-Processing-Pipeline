	system u0 (
		.clk_clk                           (<connected-to-clk_clk>),                           //                         clk.clk
		.new_sdram_controller_0_wire_addr  (<connected-to-new_sdram_controller_0_wire_addr>),  // new_sdram_controller_0_wire.addr
		.new_sdram_controller_0_wire_ba    (<connected-to-new_sdram_controller_0_wire_ba>),    //                            .ba
		.new_sdram_controller_0_wire_cas_n (<connected-to-new_sdram_controller_0_wire_cas_n>), //                            .cas_n
		.new_sdram_controller_0_wire_cke   (<connected-to-new_sdram_controller_0_wire_cke>),   //                            .cke
		.new_sdram_controller_0_wire_cs_n  (<connected-to-new_sdram_controller_0_wire_cs_n>),  //                            .cs_n
		.new_sdram_controller_0_wire_dq    (<connected-to-new_sdram_controller_0_wire_dq>),    //                            .dq
		.new_sdram_controller_0_wire_dqm   (<connected-to-new_sdram_controller_0_wire_dqm>),   //                            .dqm
		.new_sdram_controller_0_wire_ras_n (<connected-to-new_sdram_controller_0_wire_ras_n>), //                            .ras_n
		.new_sdram_controller_0_wire_we_n  (<connected-to-new_sdram_controller_0_wire_we_n>),  //                            .we_n
		.pio_mode_export                   (<connected-to-pio_mode_export>),                   //                    pio_mode.export
		.pio_sw_export                     (<connected-to-pio_sw_export>),                     //                      pio_sw.export
		.pio_threshold_export              (<connected-to-pio_threshold_export>),              //               pio_threshold.export
		.reset_reset_n                     (<connected-to-reset_reset_n>),                     //                       reset.reset_n
		.sdram_read_bridge_waitrequest     (<connected-to-sdram_read_bridge_waitrequest>),     //           sdram_read_bridge.waitrequest
		.sdram_read_bridge_readdata        (<connected-to-sdram_read_bridge_readdata>),        //                            .readdata
		.sdram_read_bridge_readdatavalid   (<connected-to-sdram_read_bridge_readdatavalid>),   //                            .readdatavalid
		.sdram_read_bridge_burstcount      (<connected-to-sdram_read_bridge_burstcount>),      //                            .burstcount
		.sdram_read_bridge_writedata       (<connected-to-sdram_read_bridge_writedata>),       //                            .writedata
		.sdram_read_bridge_address         (<connected-to-sdram_read_bridge_address>),         //                            .address
		.sdram_read_bridge_write           (<connected-to-sdram_read_bridge_write>),           //                            .write
		.sdram_read_bridge_read            (<connected-to-sdram_read_bridge_read>),            //                            .read
		.sdram_read_bridge_byteenable      (<connected-to-sdram_read_bridge_byteenable>),      //                            .byteenable
		.sdram_read_bridge_debugaccess     (<connected-to-sdram_read_bridge_debugaccess>),     //                            .debugaccess
		.sdram_write_bridge_waitrequest    (<connected-to-sdram_write_bridge_waitrequest>),    //          sdram_write_bridge.waitrequest
		.sdram_write_bridge_readdata       (<connected-to-sdram_write_bridge_readdata>),       //                            .readdata
		.sdram_write_bridge_readdatavalid  (<connected-to-sdram_write_bridge_readdatavalid>),  //                            .readdatavalid
		.sdram_write_bridge_burstcount     (<connected-to-sdram_write_bridge_burstcount>),     //                            .burstcount
		.sdram_write_bridge_writedata      (<connected-to-sdram_write_bridge_writedata>),      //                            .writedata
		.sdram_write_bridge_address        (<connected-to-sdram_write_bridge_address>),        //                            .address
		.sdram_write_bridge_write          (<connected-to-sdram_write_bridge_write>),          //                            .write
		.sdram_write_bridge_read           (<connected-to-sdram_write_bridge_read>),           //                            .read
		.sdram_write_bridge_byteenable     (<connected-to-sdram_write_bridge_byteenable>),     //                            .byteenable
		.sdram_write_bridge_debugaccess    (<connected-to-sdram_write_bridge_debugaccess>),    //                            .debugaccess
		.img_load_export                   (<connected-to-img_load_export>)                    //                    img_load.export
	);

