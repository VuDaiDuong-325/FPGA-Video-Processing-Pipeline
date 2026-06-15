module Sharpen_Filter (
    // Window 3x3 cho từng kênh (center = p11)
    input  wire [9:0]  rp01, rp10, rp11, rp12, rp21,
    input  wire [9:0]  gp01, gp10, gp11, gp12, gp21,
    input  wire [9:0]  bp01, bp10, bp11, bp12, bp21,

    output wire [9:0]  oRed,
    output wire [9:0]  oGreen,
    output wire [9:0]  oBlue
);

    // out = 5*center - (up+down+left+right), clamp [0,1023]
    function [9:0] sharpen_clamp;
        input [9:0] c, up, down, left, right;
        reg signed [13:0] s_result; // 5*1023=5115 max, đủ 13-bit; dùng 14 cho an toàn signed
        begin
            s_result = ($signed({4'b0,c}) * 14'sd5)
                     - $signed({4'b0,up}) - $signed({4'b0,down})
                     - $signed({4'b0,left}) - $signed({4'b0,right});

            if (s_result < 0)
                sharpen_clamp = 10'd0;
            else if (s_result > 14'sd1023)
                sharpen_clamp = 10'd1023;
            else
                sharpen_clamp = s_result[9:0];
        end
    endfunction

    assign oRed   = sharpen_clamp(rp11, rp01, rp21, rp10, rp12);
    assign oGreen = sharpen_clamp(gp11, gp01, gp21, gp10, gp12);
    assign oBlue  = sharpen_clamp(bp11, bp01, bp21, bp10, bp12);

endmodule