library verilog;
use verilog.vl_types.all;
entity sdram_double_buffer_controller is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        cam_vsync       : in     vl_logic;
        cam_pixel_valid : in     vl_logic;
        cam_pixel_data  : in     vl_logic_vector(15 downto 0);
        avm_address     : out    vl_logic_vector(24 downto 0);
        avm_writedata   : out    vl_logic_vector(15 downto 0);
        avm_write       : out    vl_logic;
        avm_waitrequest : in     vl_logic
    );
end sdram_double_buffer_controller;
