	component system is
		port (
			clk_clk                           : in    std_logic                     := 'X';             -- clk
			new_sdram_controller_0_wire_addr  : out   std_logic_vector(12 downto 0);                    -- addr
			new_sdram_controller_0_wire_ba    : out   std_logic_vector(1 downto 0);                     -- ba
			new_sdram_controller_0_wire_cas_n : out   std_logic;                                        -- cas_n
			new_sdram_controller_0_wire_cke   : out   std_logic;                                        -- cke
			new_sdram_controller_0_wire_cs_n  : out   std_logic;                                        -- cs_n
			new_sdram_controller_0_wire_dq    : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			new_sdram_controller_0_wire_dqm   : out   std_logic_vector(1 downto 0);                     -- dqm
			new_sdram_controller_0_wire_ras_n : out   std_logic;                                        -- ras_n
			new_sdram_controller_0_wire_we_n  : out   std_logic;                                        -- we_n
			pio_mode_export                   : out   std_logic_vector(1 downto 0);                     -- export
			pio_sw_export                     : in    std_logic_vector(9 downto 0)  := (others => 'X'); -- export
			pio_threshold_export              : out   std_logic_vector(7 downto 0);                     -- export
			reset_reset_n                     : in    std_logic                     := 'X';             -- reset_n
			sdram_read_bridge_waitrequest     : out   std_logic;                                        -- waitrequest
			sdram_read_bridge_readdata        : out   std_logic_vector(15 downto 0);                    -- readdata
			sdram_read_bridge_readdatavalid   : out   std_logic;                                        -- readdatavalid
			sdram_read_bridge_burstcount      : in    std_logic_vector(0 downto 0)  := (others => 'X'); -- burstcount
			sdram_read_bridge_writedata       : in    std_logic_vector(15 downto 0) := (others => 'X'); -- writedata
			sdram_read_bridge_address         : in    std_logic_vector(25 downto 0) := (others => 'X'); -- address
			sdram_read_bridge_write           : in    std_logic                     := 'X';             -- write
			sdram_read_bridge_read            : in    std_logic                     := 'X';             -- read
			sdram_read_bridge_byteenable      : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- byteenable
			sdram_read_bridge_debugaccess     : in    std_logic                     := 'X';             -- debugaccess
			sdram_write_bridge_waitrequest    : out   std_logic;                                        -- waitrequest
			sdram_write_bridge_readdata       : out   std_logic_vector(15 downto 0);                    -- readdata
			sdram_write_bridge_readdatavalid  : out   std_logic;                                        -- readdatavalid
			sdram_write_bridge_burstcount     : in    std_logic_vector(0 downto 0)  := (others => 'X'); -- burstcount
			sdram_write_bridge_writedata      : in    std_logic_vector(15 downto 0) := (others => 'X'); -- writedata
			sdram_write_bridge_address        : in    std_logic_vector(25 downto 0) := (others => 'X'); -- address
			sdram_write_bridge_write          : in    std_logic                     := 'X';             -- write
			sdram_write_bridge_read           : in    std_logic                     := 'X';             -- read
			sdram_write_bridge_byteenable     : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- byteenable
			sdram_write_bridge_debugaccess    : in    std_logic                     := 'X';             -- debugaccess
			img_load_export                   : out   std_logic                                         -- export
		);
	end component system;

	u0 : component system
		port map (
			clk_clk                           => CONNECTED_TO_clk_clk,                           --                         clk.clk
			new_sdram_controller_0_wire_addr  => CONNECTED_TO_new_sdram_controller_0_wire_addr,  -- new_sdram_controller_0_wire.addr
			new_sdram_controller_0_wire_ba    => CONNECTED_TO_new_sdram_controller_0_wire_ba,    --                            .ba
			new_sdram_controller_0_wire_cas_n => CONNECTED_TO_new_sdram_controller_0_wire_cas_n, --                            .cas_n
			new_sdram_controller_0_wire_cke   => CONNECTED_TO_new_sdram_controller_0_wire_cke,   --                            .cke
			new_sdram_controller_0_wire_cs_n  => CONNECTED_TO_new_sdram_controller_0_wire_cs_n,  --                            .cs_n
			new_sdram_controller_0_wire_dq    => CONNECTED_TO_new_sdram_controller_0_wire_dq,    --                            .dq
			new_sdram_controller_0_wire_dqm   => CONNECTED_TO_new_sdram_controller_0_wire_dqm,   --                            .dqm
			new_sdram_controller_0_wire_ras_n => CONNECTED_TO_new_sdram_controller_0_wire_ras_n, --                            .ras_n
			new_sdram_controller_0_wire_we_n  => CONNECTED_TO_new_sdram_controller_0_wire_we_n,  --                            .we_n
			pio_mode_export                   => CONNECTED_TO_pio_mode_export,                   --                    pio_mode.export
			pio_sw_export                     => CONNECTED_TO_pio_sw_export,                     --                      pio_sw.export
			pio_threshold_export              => CONNECTED_TO_pio_threshold_export,              --               pio_threshold.export
			reset_reset_n                     => CONNECTED_TO_reset_reset_n,                     --                       reset.reset_n
			sdram_read_bridge_waitrequest     => CONNECTED_TO_sdram_read_bridge_waitrequest,     --           sdram_read_bridge.waitrequest
			sdram_read_bridge_readdata        => CONNECTED_TO_sdram_read_bridge_readdata,        --                            .readdata
			sdram_read_bridge_readdatavalid   => CONNECTED_TO_sdram_read_bridge_readdatavalid,   --                            .readdatavalid
			sdram_read_bridge_burstcount      => CONNECTED_TO_sdram_read_bridge_burstcount,      --                            .burstcount
			sdram_read_bridge_writedata       => CONNECTED_TO_sdram_read_bridge_writedata,       --                            .writedata
			sdram_read_bridge_address         => CONNECTED_TO_sdram_read_bridge_address,         --                            .address
			sdram_read_bridge_write           => CONNECTED_TO_sdram_read_bridge_write,           --                            .write
			sdram_read_bridge_read            => CONNECTED_TO_sdram_read_bridge_read,            --                            .read
			sdram_read_bridge_byteenable      => CONNECTED_TO_sdram_read_bridge_byteenable,      --                            .byteenable
			sdram_read_bridge_debugaccess     => CONNECTED_TO_sdram_read_bridge_debugaccess,     --                            .debugaccess
			sdram_write_bridge_waitrequest    => CONNECTED_TO_sdram_write_bridge_waitrequest,    --          sdram_write_bridge.waitrequest
			sdram_write_bridge_readdata       => CONNECTED_TO_sdram_write_bridge_readdata,       --                            .readdata
			sdram_write_bridge_readdatavalid  => CONNECTED_TO_sdram_write_bridge_readdatavalid,  --                            .readdatavalid
			sdram_write_bridge_burstcount     => CONNECTED_TO_sdram_write_bridge_burstcount,     --                            .burstcount
			sdram_write_bridge_writedata      => CONNECTED_TO_sdram_write_bridge_writedata,      --                            .writedata
			sdram_write_bridge_address        => CONNECTED_TO_sdram_write_bridge_address,        --                            .address
			sdram_write_bridge_write          => CONNECTED_TO_sdram_write_bridge_write,          --                            .write
			sdram_write_bridge_read           => CONNECTED_TO_sdram_write_bridge_read,           --                            .read
			sdram_write_bridge_byteenable     => CONNECTED_TO_sdram_write_bridge_byteenable,     --                            .byteenable
			sdram_write_bridge_debugaccess    => CONNECTED_TO_sdram_write_bridge_debugaccess,    --                            .debugaccess
			img_load_export                   => CONNECTED_TO_img_load_export                    --                    img_load.export
		);

