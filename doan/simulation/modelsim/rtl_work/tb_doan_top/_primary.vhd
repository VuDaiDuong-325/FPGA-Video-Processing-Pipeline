library verilog;
use verilog.vl_types.all;
entity tb_doan_top is
    generic(
        CLK50_PERIOD    : integer := 20;
        CLK25_PERIOD    : integer := 40;
        PCLK_PERIOD     : integer := 41;
        H_ACTIVE        : integer := 640;
        V_ACTIVE        : integer := 480;
        TOTAL_PIXELS    : vl_notype
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CLK50_PERIOD : constant is 1;
    attribute mti_svvh_generic_type of CLK25_PERIOD : constant is 1;
    attribute mti_svvh_generic_type of PCLK_PERIOD : constant is 1;
    attribute mti_svvh_generic_type of H_ACTIVE : constant is 1;
    attribute mti_svvh_generic_type of V_ACTIVE : constant is 1;
    attribute mti_svvh_generic_type of TOTAL_PIXELS : constant is 3;
end tb_doan_top;
