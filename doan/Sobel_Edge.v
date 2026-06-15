module Sobel_Edge #(
    parameter [10:0] THRESHOLD = 11'd300  // Ngưỡng |G|
) (
    input  wire [9:0]  p00, p01, p02,
    input  wire [9:0]  p10, p11, p12,
    input  wire [9:0]  p20, p21, p22,

    output wire [9:0]  oRed,
    output wire [9:0]  oGreen,
    output wire [9:0]  oBlue
);

    // Gx = (p02 + 2*p12 + p22) - (p00 + 2*p10 + p20)
    // Gy = (p20 + 2*p21 + p22) - (p00 + 2*p01 + p02)
    // Dùng signed 13-bit đủ chứa: max |Gx|,|Gy| = 4*1023 = 4092 (12-bit unsigned, 13-bit signed an toàn)

    wire signed [12:0] s_gx = $signed({1'b0, p02}) + $signed({1'b0, p12, 1'b0})
                            + $signed({1'b0, p22})
                            - $signed({1'b0, p00}) - $signed({1'b0, p10, 1'b0})
                            - $signed({1'b0, p20});

    wire signed [12:0] s_gy = $signed({1'b0, p20}) + $signed({1'b0, p21, 1'b0})
                            + $signed({1'b0, p22})
                            - $signed({1'b0, p00}) - $signed({1'b0, p01, 1'b0})
                            - $signed({1'b0, p02});

    wire [11:0] abs_gx = s_gx[12] ? (~s_gx + 1'b1) : s_gx;
    wire [11:0] abs_gy = s_gy[12] ? (~s_gy + 1'b1) : s_gy;

    wire [12:0] g_sum = abs_gx + abs_gy; // max 8184, 13-bit đủ

    wire is_edge = (g_sum > {2'b00, THRESHOLD});

    wire [9:0] edge_val = is_edge ? 10'd1023 : 10'd0;

    assign oRed   = edge_val;
    assign oGreen = edge_val;
    assign oBlue  = edge_val;

endmodule