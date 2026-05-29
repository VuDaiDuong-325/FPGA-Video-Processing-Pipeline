module YUV444_to_RGB10(
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire        i_valid,
    
    // Input 8-bit Full Range YUV (Từ module YUV422_to_444)
    input  wire [7:0]  iY,
    input  wire [7:0]  iCb,
    input  wire [7:0]  iCr,
    
    // Output 10-bit RGB (Nối thẳng vào VGA_controller)
    output reg         o_valid,
    output reg  [9:0]  oRed,
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue
);

    // =====================================================================
    // PIPELINE STAGE 1: Tự động nội suy DSP (Multipliers)
    // Hệ số đã được nhân với 128 và thiết kế để xuất ra dải 10-bit trực tiếp
    // Công thức Full Range: Y*1.0,  Cb/Cr offset -128
    // =====================================================================
    reg signed [21:0] r_X, r_Y, r_Z;
    reg               r_val_d1;

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            r_X      <= 22'sd0;
            r_Y      <= 22'sd0;
            r_Z      <= 22'sd0;
            r_val_d1 <= 1'b0;
        end else begin
            r_val_d1 <= i_valid;
            if (i_valid) begin
                // Terasic Trick: Gộp phép trừ 128 thành 1 hằng số khổng lồ
                r_X <= (10'd512 * iY) + (10'd718 * iCr) - 22'd91881;
                r_Y <= (10'd512 * iY) - (10'd176 * iCb) - (10'd366 * iCr) + 22'd69337;
                r_Z <= (10'd512 * iY) + (10'd907 * iCb) - 22'd116130;
            end
        end
    end

    // =====================================================================
    // PIPELINE STAGE 2: Dịch bit (>> 7) và Khống chế dải 10-bit (Clipping)
    // =====================================================================
    wire signed [21:0] w_X_out = r_X >>> 7;
    wire signed [21:0] w_Y_out = r_Y >>> 7;
    wire signed [21:0] w_Z_out = r_Z >>> 7;

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oRed    <= 10'd0;
            oGreen  <= 10'd0;
            oBlue   <= 10'd0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= r_val_d1;
            
            // RED
            if (w_X_out[21])            // Nếu giá trị âm (bit dấu = 1)
                oRed <= 10'd0;
            else if (w_X_out > 10'd1023) // Nếu tràn mức 10-bit
                oRed <= 10'd1023;
            else
                oRed <= w_X_out[9:0];

            // GREEN
            if (w_Y_out[21])
                oGreen <= 10'd0;
            else if (w_Y_out > 10'd1023)
                oGreen <= 10'd1023;
            else
                oGreen <= w_Y_out[9:0];

            // BLUE
            if (w_Z_out[21])
                oBlue <= 10'd0;
            else if (w_Z_out > 10'd1023)
                oBlue <= 10'd1023;
            else
                oBlue <= w_Z_out[9:0];
        end
    end

endmodule