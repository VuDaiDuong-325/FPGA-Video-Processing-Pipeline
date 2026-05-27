	system u0 (
		.cam_bank_export    (<connected-to-cam_bank_export>),    //    cam_bank.export
		.cam_din_export     (<connected-to-cam_din_export>),     //     cam_din.export
		.cam_fifo_export    (<connected-to-cam_fifo_export>),    //    cam_fifo.export
		.cam_href_export    (<connected-to-cam_href_export>),    //    cam_href.export
		.cam_pclk_export    (<connected-to-cam_pclk_export>),    //    cam_pclk.export
		.cam_vsync_export   (<connected-to-cam_vsync_export>),   //   cam_vsync.export
		.clk_clk            (<connected-to-clk_clk>),            //         clk.clk
		.reset_reset_n      (<connected-to-reset_reset_n>),      //       reset.reset_n
		.sdram_wire_addr    (<connected-to-sdram_wire_addr>),    //  sdram_wire.addr
		.sdram_wire_ba      (<connected-to-sdram_wire_ba>),      //            .ba
		.sdram_wire_cas_n   (<connected-to-sdram_wire_cas_n>),   //            .cas_n
		.sdram_wire_cke     (<connected-to-sdram_wire_cke>),     //            .cke
		.sdram_wire_cs_n    (<connected-to-sdram_wire_cs_n>),    //            .cs_n
		.sdram_wire_dq      (<connected-to-sdram_wire_dq>),      //            .dq
		.sdram_wire_dqm     (<connected-to-sdram_wire_dqm>),     //            .dqm
		.sdram_wire_ras_n   (<connected-to-sdram_wire_ras_n>),   //            .ras_n
		.sdram_wire_we_n    (<connected-to-sdram_wire_we_n>),    //            .we_n
		.vga_b_export       (<connected-to-vga_b_export>),       //       vga_b.export
		.vga_bank_export    (<connected-to-vga_bank_export>),    //    vga_bank.export
		.vga_blank_n_export (<connected-to-vga_blank_n_export>), // vga_blank_n.export
		.vga_clk_export     (<connected-to-vga_clk_export>),     //     vga_clk.export
		.vga_g_export       (<connected-to-vga_g_export>),       //       vga_g.export
		.vga_hsync_export   (<connected-to-vga_hsync_export>),   //   vga_hsync.export
		.vga_r_export       (<connected-to-vga_r_export>),       //       vga_r.export
		.vga_sync_n_export  (<connected-to-vga_sync_n_export>),  //  vga_sync_n.export
		.vga_vsync_export   (<connected-to-vga_vsync_export>)    //   vga_vsync.export
	);

