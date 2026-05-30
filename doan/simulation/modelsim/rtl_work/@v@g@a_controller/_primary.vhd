library verilog;
use verilog.vl_types.all;
entity VGA_controller is
    generic(
        H_FRONT         : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        H_SYNC          : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        H_BACK          : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0);
        H_ACT           : vl_logic_vector(10 downto 0) := (Hi0, Hi1, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        H_BLANK         : vl_logic_vector(10 downto 0);
        H_TOTAL         : vl_logic_vector(10 downto 0);
        V_FRONT         : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0);
        V_SYNC          : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0);
        V_BACK          : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi1);
        V_ACT           : vl_logic_vector(10 downto 0) := (Hi0, Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        V_BLANK         : vl_logic_vector(10 downto 0);
        V_TOTAL         : vl_logic_vector(10 downto 0)
    );
    port(
        iRed            : in     vl_logic_vector(9 downto 0);
        iGreen          : in     vl_logic_vector(9 downto 0);
        iBlue           : in     vl_logic_vector(9 downto 0);
        oCurrent_X      : out    vl_logic_vector(10 downto 0);
        oCurrent_Y      : out    vl_logic_vector(10 downto 0);
        oAddress        : out    vl_logic_vector(21 downto 0);
        oRequest        : out    vl_logic;
        oVGA_R          : out    vl_logic_vector(9 downto 0);
        oVGA_G          : out    vl_logic_vector(9 downto 0);
        oVGA_B          : out    vl_logic_vector(9 downto 0);
        oVGA_HS         : out    vl_logic;
        oVGA_VS         : out    vl_logic;
        oVGA_SYNC       : out    vl_logic;
        oVGA_BLANK      : out    vl_logic;
        oVGA_CLOCK      : out    vl_logic;
        iCLK            : in     vl_logic;
        iRST_N          : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of H_FRONT : constant is 2;
    attribute mti_svvh_generic_type of H_SYNC : constant is 2;
    attribute mti_svvh_generic_type of H_BACK : constant is 2;
    attribute mti_svvh_generic_type of H_ACT : constant is 2;
    attribute mti_svvh_generic_type of H_BLANK : constant is 4;
    attribute mti_svvh_generic_type of H_TOTAL : constant is 4;
    attribute mti_svvh_generic_type of V_FRONT : constant is 2;
    attribute mti_svvh_generic_type of V_SYNC : constant is 2;
    attribute mti_svvh_generic_type of V_BACK : constant is 2;
    attribute mti_svvh_generic_type of V_ACT : constant is 2;
    attribute mti_svvh_generic_type of V_BLANK : constant is 4;
    attribute mti_svvh_generic_type of V_TOTAL : constant is 4;
end VGA_controller;
