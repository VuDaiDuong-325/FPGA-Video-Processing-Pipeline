module YUV422_to_444(
    // YUV 4:2:2 Input
    input  wire [15:0] iYCbCr,
    input  wire        i_valid,
    
    // YUV 4:4:4 Output (Được trễ 1 chu kỳ clock so với Input)
    output reg  [7:0]  oY,
    output reg  [7:0]  oCb,
    output reg  [7:0]  oCr,
    
    // Control Signals
    input  wire [9:0]  iX,     // iX này BẮT BUỘC phải là vga_x_d1
    input  wire        iCLK,
    input  wire        iRST_N
);

    // Thanh ghi nội bộ để lưu trữ chéo các thành phần màu
    reg [7:0] Y_delay;
    reg [7:0] Cb_delay;
    reg [7:0] Cr_delay;

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            oY       <= 8'd0;
            oCb      <= 8'd128;
            oCr      <= 8'd128;
            Y_delay  <= 8'd0;
            Cb_delay <= 8'd128;
            Cr_delay <= 8'd128;
        end 
        else if (i_valid) begin
            if (!iX[0]) begin 
                // =========================================================
                // THỜI ĐIỂM iX LÀ SỐ CHẴN (VD: iX = 0, 2, 4...)
                // Dữ liệu vào: iYCbCr = {Cb_mới, Y_chẵn}
                // =========================================================
                // 1. Xuất ra màn hình Pixel (x-1) [Là Pixel Lẻ trước đó]
                oY  <= Y_delay;   // Lấy Y lẻ từ nhịp trước
                oCb <= Cb_delay;  // Lấy Cb cũ đã lưu
                oCr <= Cr_delay;  // Lấy Cr cũ đã lưu
                
                // 2. Chốt dữ liệu hiện tại để dành cho nhịp sau
                Cb_delay <= iYCbCr[15:8]; // Chốt Cb_mới cho 2 pixel tiếp theo
                Y_delay  <= iYCbCr[7:0];  // Chốt Y_chẵn (Để nhịp sau mới xuất)
            end 
            else begin 
                // =========================================================
                // THỜI ĐIỂM iX LÀ SỐ LẺ (VD: iX = 1, 3, 5...)
                // Dữ liệu vào: iYCbCr = {Cr_mới, Y_lẻ}
                // =========================================================
                // 1. Xuất ra màn hình Pixel (x-1) [Là Pixel Chẵn trước đó]
                oY  <= Y_delay;       // Lấy Y chẵn (đã chốt ở nhịp trước)
                oCb <= Cb_delay;      // Lấy Cb (đã chốt ở nhịp trước)
                oCr <= iYCbCr[15:8];  // Ghép ngay với Cr_mới vừa tới! (MẢNH GHÉP CUỐI CÙNG)
                
                // 2. Chốt dữ liệu hiện tại để dành cho nhịp sau
                Cr_delay <= iYCbCr[15:8]; // Chốt Cr_mới để dùng cho Pixel Lẻ ở nhịp kế
                Y_delay  <= iYCbCr[7:0];  // Chốt Y_lẻ (Để nhịp sau xuất)
            end
        end
    end

endmodule