module VGA_Image_Processor (
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire [1:0]  iMode,

    input  wire        i_valid,
    input  wire [10:0] i_x,      
    input  wire [10:0] i_y,      
    input  wire [9:0]  iRed,
    input  wire [9:0]  iGreen,
    input  wire [9:0]  iBlue,

    output reg  [9:0]  oRed,
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue,
    output reg         o_valid
);
    // Line buffer 3x3 dùng chung: gộp {R,G,B} = 30-bit/word
    // Latency = 2 cycle
    wire [29:0] rgb_in = {iRed, iGreen, iBlue};

    wire [29:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;
    wire        lb_valid, lb_edge_pixel;

    line_buffer3x3 #(.WIDTH(30), .IMG_W(640), .IMG_H(480)) u_line_buf (
        .iCLK         (iCLK),
        .iRST_N       (iRST_N),
        .i_valid      (i_valid),
        .i_x          (i_x),
        .i_y          (i_y),
        .iData        (rgb_in),
        .p00(w00), .p01(w01), .p02(w02),
        .p10(w10), .p11(w11), .p12(w12),
        .p20(w20), .p21(w21), .p22(w22),
        .o_valid       (lb_valid),
        .o_edge_pixel  (lb_edge_pixel)
    );

    // Tách từng kênh từ window 30-bit
    wire [9:0] r00=w00[29:20], g00=w00[19:10], b00=w00[9:0];
    wire [9:0] r01=w01[29:20], g01=w01[19:10], b01=w01[9:0];
    wire [9:0] r02=w02[29:20], g02=w02[19:10], b02=w02[9:0];
    wire [9:0] r10=w10[29:20], g10=w10[19:10], b10=w10[9:0];
    wire [9:0] r11=w11[29:20], g11=w11[19:10], b11=w11[9:0];
    wire [9:0] r12=w12[29:20], g12=w12[19:10], b12=w12[9:0];
    wire [9:0] r20=w20[29:20], g20=w20[19:10], b20=w20[9:0];
    wire [9:0] r21=w21[29:20], g21=w21[19:10], b21=w21[9:0];
    wire [9:0] r22=w22[29:20], g22=w22[19:10], b22=w22[9:0];

    // ---------------------------------------------------------------
    // Mode 2'b00/01: cần delay matching = line_buffer's "center pixel"
    //   Center của window = (x_pipe2, y_pipe2) tương đương w11 = pixel
    //   đã trễ 2 cycle. Dùng trực tiếp w11 (= RGB của pixel trung tâm).
    // ---------------------------------------------------------------
    wire [9:0] center_r = r11, center_g = g11, center_b = b11;

    // ---------------------------------------------------------------
    // Mode 2'b01: Grayscale BT.601 trên pixel trung tâm
    //   luma = (77*R + 150*G + 29*B) >> 8
    // ---------------------------------------------------------------
    wire [19:0] luma_full = (20'd77  * {10'd0, center_r})
                          + (20'd150 * {10'd0, center_g})
                          + (20'd29  * {10'd0, center_b});
    wire [9:0]  gray_val  = luma_full[17:8];

    // ---------------------------------------------------------------
    // Mode 2'b10: Sobel Edge - cần luma của cả 9 pixel trong window
    // ---------------------------------------------------------------
    function [9:0] f_luma;
        input [9:0] r, g, b;
        reg [19:0] lf;
        begin
            lf = (20'd77*{10'd0,r}) + (20'd150*{10'd0,g}) + (20'd29*{10'd0,b});
            f_luma = lf[17:8];
        end
    endfunction

    wire [9:0] luma00=f_luma(r00,g00,b00), luma01=f_luma(r01,g01,b01), luma02=f_luma(r02,g02,b02);
    wire [9:0] luma10=f_luma(r10,g10,b10), luma11=f_luma(r11,g11,b11), luma12=f_luma(r12,g12,b12);
    wire [9:0] luma20=f_luma(r20,g20,b20), luma21=f_luma(r21,g21,b21), luma22=f_luma(r22,g22,b22);

    wire [9:0] sobel_r, sobel_g, sobel_b;

    Sobel_Edge #(.THRESHOLD(11'd300)) u_sobel (
        .p00(luma00), .p01(luma01), .p02(luma02),
        .p10(luma10), .p11(luma11), .p12(luma12),
        .p20(luma20), .p21(luma21), .p22(luma22),
        .oRed(sobel_r), .oGreen(sobel_g), .oBlue(sobel_b)
    );

    // ---------------------------------------------------------------
    // Mode 2'b11: Sharpen (Unsharp Mask) trên ảnh màu, dùng cross (+) 5pt
    // ---------------------------------------------------------------
    wire [9:0] sharp_r, sharp_g, sharp_b;

    Sharpen_Filter u_sharpen (
        .rp01(r01), .rp10(r10), .rp11(r11), .rp12(r12), .rp21(r21),
        .gp01(g01), .gp10(g10), .gp11(g11), .gp12(g12), .gp21(g21),
        .bp01(b01), .bp10(b10), .bp11(b11), .bp12(b12), .bp21(b21),
        .oRed(sharp_r), .oGreen(sharp_g), .oBlue(sharp_b)
    );

    // ---------------------------------------------------------------
    // Stage cuối: MUX theo iMode, đăng ký output (1 cycle)
    //   RGB gốc / Grayscale dùng center pixel (w11, đã trễ 2 cycle bởi
    //   line buffer) + thêm 1 cycle register tại đây = tổng 3 cycle,
    //   KHỚP với latency của Sobel/Sharpen (2 cycle line_buf + 1 cycle
    //   compute trong chính 2 module đó).
    // ---------------------------------------------------------------
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oRed    <= 10'd0;
            oGreen  <= 10'd0;
            oBlue   <= 10'd0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= lb_valid;
            case (iMode)
                2'b00: begin   // Ảnh màu RGB gốc (pixel trung tâm window)
                    oRed   <= center_r;
                    oGreen <= center_g;
                    oBlue  <= center_b;
                end
                2'b01: begin   // Ảnh xám Grayscale
                    oRed   <= gray_val;
                    oGreen <= gray_val;
                    oBlue  <= gray_val;
                end
                2'b10: begin   // Sobel Edge (binary edge map)
                    if (lb_edge_pixel) begin
                        // Viền ảnh: chưa đủ window 3x3 -> đen, tránh artifact
                        oRed   <= 10'd0;
                        oGreen <= 10'd0;
                        oBlue  <= 10'd0;
                    end else begin
                        oRed   <= sobel_r;
                        oGreen <= sobel_g;
                        oBlue  <= sobel_b;
                    end
                end
                2'b11: begin   // Sharpen (Unsharp Masking)
                    if (lb_edge_pixel) begin
                        // Viền ảnh: bypass, giữ nguyên pixel gốc
                        oRed   <= center_r;
                        oGreen <= center_g;
                        oBlue  <= center_b;
                    end else begin
                        oRed   <= sharp_r;
                        oGreen <= sharp_g;
                        oBlue  <= sharp_b;
                    end
                end
            endcase
        end
    end

endmodule