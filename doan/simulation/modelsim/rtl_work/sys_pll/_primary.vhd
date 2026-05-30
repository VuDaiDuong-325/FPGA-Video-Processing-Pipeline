library verilog;
use verilog.vl_types.all;
entity sys_pll is
    port(
        locked          : out    vl_logic;
        outclk_0        : out    vl_logic;
        outclk_1        : out    vl_logic;
        outclk_2        : out    vl_logic;
        refclk          : in     vl_logic;
        rst             : in     vl_logic
    );
end sys_pll;
