library verilog;
use verilog.vl_types.all;
entity YUV422_to_444 is
    port(
        iYCbCr          : in     vl_logic_vector(15 downto 0);
        i_valid         : in     vl_logic;
        oY              : out    vl_logic_vector(7 downto 0);
        oCb             : out    vl_logic_vector(7 downto 0);
        oCr             : out    vl_logic_vector(7 downto 0);
        iX              : in     vl_logic_vector(9 downto 0);
        iCLK            : in     vl_logic;
        iRST_N          : in     vl_logic
    );
end YUV422_to_444;
