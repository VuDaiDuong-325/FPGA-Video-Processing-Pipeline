library verilog;
use verilog.vl_types.all;
entity sdram_read_controller is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        frame_done      : in     vl_logic;
        avm_address     : out    vl_logic_vector(24 downto 0);
        avm_read        : out    vl_logic;
        avm_waitrequest : in     vl_logic;
        avm_readdata    : in     vl_logic_vector(15 downto 0);
        avm_readdatavalid: in     vl_logic;
        fifo_wrreq      : out    vl_logic;
        fifo_wrdata     : out    vl_logic_vector(15 downto 0);
        fifo_wrusedw    : in     vl_logic_vector(10 downto 0)
    );
end sdram_read_controller;
