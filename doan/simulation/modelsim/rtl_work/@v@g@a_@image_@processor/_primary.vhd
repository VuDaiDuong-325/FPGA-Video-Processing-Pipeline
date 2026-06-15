library verilog;
use verilog.vl_types.all;
entity VGA_Image_Processor is
    port(
        iCLK            : in     vl_logic;
        iRST_N          : in     vl_logic;
        iMode           : in     vl_logic_vector(1 downto 0);
        i_valid         : in     vl_logic;
        iY              : in     vl_logic_vector(7 downto 0);
        iCb             : in     vl_logic_vector(7 downto 0);
        iCr             : in     vl_logic_vector(7 downto 0);
        oRed            : out    vl_logic_vector(9 downto 0);
        oGreen          : out    vl_logic_vector(9 downto 0);
        oBlue           : out    vl_logic_vector(9 downto 0)
    );
end VGA_Image_Processor;
