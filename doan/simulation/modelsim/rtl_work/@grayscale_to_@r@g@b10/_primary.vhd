library verilog;
use verilog.vl_types.all;
entity Grayscale_to_RGB10 is
    port(
        iCLK            : in     vl_logic;
        iRST_N          : in     vl_logic;
        i_valid         : in     vl_logic;
        iY              : in     vl_logic_vector(7 downto 0);
        o_valid         : out    vl_logic;
        oRed            : out    vl_logic_vector(9 downto 0);
        oGreen          : out    vl_logic_vector(9 downto 0);
        oBlue           : out    vl_logic_vector(9 downto 0)
    );
end Grayscale_to_RGB10;
