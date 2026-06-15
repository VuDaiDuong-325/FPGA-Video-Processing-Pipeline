// =========================================================================
// MODULE: VGA_Image_Processor.v
// =========================================================================

module VGA_Image_Processor (
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire [1:0]  iMode,

    input  wire        i_valid,
    input  wire [9:0]  iRed,
    input  wire [9:0]  iGreen,
    input  wire [9:0]  iBlue,

    output reg  [9:0]  oRed,
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue
);

    wire [9:0] gray_r, gray_g, gray_b;

    Grayscale_to_RGB10 u_Grayscale (
        .iCLK    (iCLK),
        .iRST_N  (iRST_N),
        .i_valid (i_valid),
        .iRed    (iRed),
        .iGreen  (iGreen),
        .iBlue   (iBlue),
        .oRed    (gray_r),
        .oGreen  (gray_g),
        .oBlue   (gray_b)
    );

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oRed   <= 10'd0;
            oGreen <= 10'd0;
            oBlue  <= 10'd0;
        end else begin
            case (iMode)
                2'b00: begin   // Ảnh màu RGB gốc
                    oRed   <= iRed;
                    oGreen <= iGreen;
                    oBlue  <= iBlue;
                end
                2'b01: begin   // Ảnh xám Grayscale
                    oRed   <= gray_r;
                    oGreen <= gray_g;
                    oBlue  <= gray_b;
                end
                default: begin // Mặc định: RGB gốc
                    oRed   <= iRed;
                    oGreen <= iGreen;
                    oBlue  <= iBlue;
                end
            endcase
        end
    end

endmodule