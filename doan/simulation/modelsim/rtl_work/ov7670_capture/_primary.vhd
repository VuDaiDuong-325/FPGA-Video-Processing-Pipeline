library verilog;
use verilog.vl_types.all;
entity ov7670_capture is
    port(
        pclk            : in     vl_logic;
        reset           : in     vl_logic;
        vsync           : in     vl_logic;
        href            : in     vl_logic;
        data_in         : in     vl_logic_vector(7 downto 0);
        data_out        : out    vl_logic_vector(15 downto 0);
        write_en        : out    vl_logic
    );
end ov7670_capture;
