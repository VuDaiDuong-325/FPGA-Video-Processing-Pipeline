	component system is
		port (
			cam_bank_export    : out   std_logic;                                        -- export
			cam_din_export     : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			cam_fifo_export    : out   std_logic;                                        -- export
			cam_href_export    : in    std_logic                     := 'X';             -- export
			cam_pclk_export    : in    std_logic                     := 'X';             -- export
			cam_vsync_export   : in    std_logic                     := 'X';             -- export
			clk_clk            : in    std_logic                     := 'X';             -- clk
			reset_reset_n      : in    std_logic                     := 'X';             -- reset_n
			sdram_wire_addr    : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_wire_ba      : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_wire_cas_n   : out   std_logic;                                        -- cas_n
			sdram_wire_cke     : out   std_logic;                                        -- cke
			sdram_wire_cs_n    : out   std_logic;                                        -- cs_n
			sdram_wire_dq      : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_wire_dqm     : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_wire_ras_n   : out   std_logic;                                        -- ras_n
			sdram_wire_we_n    : out   std_logic;                                        -- we_n
			vga_b_export       : out   std_logic_vector(4 downto 0);                     -- export
			vga_bank_export    : in    std_logic                     := 'X';             -- export
			vga_blank_n_export : out   std_logic;                                        -- export
			vga_clk_export     : in    std_logic                     := 'X';             -- export
			vga_g_export       : out   std_logic_vector(5 downto 0);                     -- export
			vga_hsync_export   : out   std_logic;                                        -- export
			vga_r_export       : out   std_logic_vector(4 downto 0);                     -- export
			vga_sync_n_export  : out   std_logic;                                        -- export
			vga_vsync_export   : out   std_logic                                         -- export
		);
	end component system;

	u0 : component system
		port map (
			cam_bank_export    => CONNECTED_TO_cam_bank_export,    --    cam_bank.export
			cam_din_export     => CONNECTED_TO_cam_din_export,     --     cam_din.export
			cam_fifo_export    => CONNECTED_TO_cam_fifo_export,    --    cam_fifo.export
			cam_href_export    => CONNECTED_TO_cam_href_export,    --    cam_href.export
			cam_pclk_export    => CONNECTED_TO_cam_pclk_export,    --    cam_pclk.export
			cam_vsync_export   => CONNECTED_TO_cam_vsync_export,   --   cam_vsync.export
			clk_clk            => CONNECTED_TO_clk_clk,            --         clk.clk
			reset_reset_n      => CONNECTED_TO_reset_reset_n,      --       reset.reset_n
			sdram_wire_addr    => CONNECTED_TO_sdram_wire_addr,    --  sdram_wire.addr
			sdram_wire_ba      => CONNECTED_TO_sdram_wire_ba,      --            .ba
			sdram_wire_cas_n   => CONNECTED_TO_sdram_wire_cas_n,   --            .cas_n
			sdram_wire_cke     => CONNECTED_TO_sdram_wire_cke,     --            .cke
			sdram_wire_cs_n    => CONNECTED_TO_sdram_wire_cs_n,    --            .cs_n
			sdram_wire_dq      => CONNECTED_TO_sdram_wire_dq,      --            .dq
			sdram_wire_dqm     => CONNECTED_TO_sdram_wire_dqm,     --            .dqm
			sdram_wire_ras_n   => CONNECTED_TO_sdram_wire_ras_n,   --            .ras_n
			sdram_wire_we_n    => CONNECTED_TO_sdram_wire_we_n,    --            .we_n
			vga_b_export       => CONNECTED_TO_vga_b_export,       --       vga_b.export
			vga_bank_export    => CONNECTED_TO_vga_bank_export,    --    vga_bank.export
			vga_blank_n_export => CONNECTED_TO_vga_blank_n_export, -- vga_blank_n.export
			vga_clk_export     => CONNECTED_TO_vga_clk_export,     --     vga_clk.export
			vga_g_export       => CONNECTED_TO_vga_g_export,       --       vga_g.export
			vga_hsync_export   => CONNECTED_TO_vga_hsync_export,   --   vga_hsync.export
			vga_r_export       => CONNECTED_TO_vga_r_export,       --       vga_r.export
			vga_sync_n_export  => CONNECTED_TO_vga_sync_n_export,  --  vga_sync_n.export
			vga_vsync_export   => CONNECTED_TO_vga_vsync_export    --   vga_vsync.export
		);

