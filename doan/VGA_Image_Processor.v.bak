// =========================================================================
// MODULE: VGA_Image_Processor
// DESCRIPTION: Khối xử lý ảnh tổng hợp, bao gồm giải mã YUV, Grayscale
//              và bộ dồn kênh MUX chọn chế độ hiển thị từ SW[1:0]
// =========================================================================

module VGA_Image_Processor (
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire [1:0]  iMode,      // SW[1:0] chọn chế độ
    
    // Tín hiệu đầu vào từ luồng lấy mẫu camera
    input  wire        i_valid,
    input  wire [7:0]  iY,
    input  wire [7:0]  iCb,
    input  wire [7:0]  iCr,
    
    // Ngõ ra RGB 10-bit đưa tới VGA Controller
    output reg  [9:0]  oRed,
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue
);

    // ---------------------------------------------------
    // 1. Dây nối nội bộ lấy dữ liệu từ các khối xử lý con
    // ---------------------------------------------------
    wire [9:0] color_r, color_g, color_b;
    wire [9:0] gray_r, gray_g, gray_b;

    // ---------------------------------------------------
    // 2. Gọi khối xử lý ảnh màu (Chế độ 0)
    // ---------------------------------------------------
    YUV444_to_RGB10 u_YUV444_to_RGB10 (
        .iCLK    (iCLK),
        .iRST_N  (iRST_N),
        .i_valid (i_valid),
        .iY      (iY),
        .iCb     (iCb),
        .iCr     (iCr),
        .o_valid (), // Bỏ trống nếu vga_controller không dùng
        .oRed    (color_r),
        .oGreen  (color_g),
        .oBlue   (color_b)
    );

    // ---------------------------------------------------
    // 3. Gọi khối xử lý ảnh xám (Chế độ 1)
    // ---------------------------------------------------
    Grayscale_to_RGB10 u_Grayscale (
        .iCLK    (iCLK),
        .iRST_N  (iRST_N),
        .i_valid (i_valid),
        .iY      (iY),
        .o_valid (), 
        .oRed    (gray_r),
        .oGreen  (gray_g),
        .oBlue   (gray_b)
    );

    // ---------------------------------------------------
    // 4. Khối MUX chọn chế độ đưa ra ngõ ra VGA
    // ---------------------------------------------------
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oRed   <= 10'd0;
            oGreen <= 10'd0;
            oBlue  <= 10'd0;
        end else begin
            case (iMode)
                2'b00: begin // Chế độ 0: Ảnh màu RGB gốc
                    oRed   <= color_r;
                    oGreen <= color_g;
                    oBlue  <= color_b;
                end
                2'b01: begin // Chế độ 1: Ảnh xám Grayscale
                    oRed   <= gray_r;
                    oGreen <= gray_g;
                    oBlue  <= gray_b;
                end
                // Chế độ dự phòng: Giữ nguyên ảnh màu
                default: begin
                    oRed   <= color_r;
                    oGreen <= color_g;
                    oBlue  <= color_b;
                end
            endcase
        end
    end

endmodule