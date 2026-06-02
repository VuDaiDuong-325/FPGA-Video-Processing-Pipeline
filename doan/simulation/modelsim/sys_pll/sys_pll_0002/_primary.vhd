library verilog;
use verilog.vl_types.all;
entity sys_pll_0002 is
    port(
        refclk          : in     vl_logic;
        rst             : in     vl_logic;
        outclk_0        : out    vl_logic;
        outclk_1        : out    vl_logic;
        outclk_2        : out    vl_logic;
        locked          : out    vl_logic
    );
end sys_pll_0002;
