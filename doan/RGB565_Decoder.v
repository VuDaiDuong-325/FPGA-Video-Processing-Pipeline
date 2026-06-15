// =========================================================================
// MODULE: RGB565_Decoder.v
// =========================================================================

module RGB565_Decoder #(
    parameter SWAP_BYTES = 0
) (
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire        i_valid,
    input  wire [15:0] iRGB565,

    output reg  [9:0]  oRed,
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue,
    output reg         o_valid
);

    // Byte swap nếu cần
    wire [15:0] w_rgb = SWAP_BYTES ? {iRGB565[7:0], iRGB565[15:8]} : iRGB565;

    // Trích xuất từng thành phần
    wire [4:0] w_r5 = w_rgb[15:11];
    wire [5:0] w_g6 = w_rgb[10:5];
    wire [4:0] w_b5 = w_rgb[4:0];

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oRed    <= 10'd0;
            oGreen  <= 10'd0;
            oBlue   <= 10'd0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;
            if (i_valid) begin
                // R5 → R10: {R5, R5} = R5 * 33  (0→0, 31→1023)
                oRed   <= {w_r5, w_r5};
                // G6 → G10: {G6, G6[5:2]} = 10 bit full range (0→0, 63→1023) 
                oGreen <= {w_g6, w_g6[5:2]};
                // B5 → B10: {B5, B5} (0→0, 31→1023) 
                oBlue  <= {w_b5, w_b5};
            end
        end
    end

endmodule