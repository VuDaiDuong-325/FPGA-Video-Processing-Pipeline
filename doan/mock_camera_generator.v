// =========================================================================
// MODULE: MOCK CAMERA GENERATOR (OV7670 YUV422 VGA SIMULATOR)
// DESCRIPTION: Giả lập chính xác hành vi thời gian (Timing) và luồng dữ liệu 
//              của Camera OV7670 ở chế độ VGA YUYV để test hệ thống FPGA.
// =========================================================================

module mock_camera_generator (
    input  wire       clk_50,       // Xung nhịp hệ thống 50MHz từ Kit DE1-SoC
    input  wire       rst_n,        // Reset tích cực mức thấp (Nút KEY[0])
    output reg        CAM_PCLK,     // Xung nhịp Pixel giả lập xuất ra
    output reg        CAM_VSYNC,    // Tín hiệu đồng bộ khung hình (Active-High)
    output reg        CAM_HREF,     // Tín hiệu báo dòng pixel hợp lệ (Active-High)
    output reg [7:0]  CAM_DATA      // Dữ liệu pixel 8-bit luồng YUYV
);

    // 1. Bộ chia tần tạo xung nhịp PCLK giả lập (50MHz / 4 = 12.5MHz)
    // Tốc độ này rất lý tưởng và mượt mà cho việc mô phỏng VGA 30 FPS bên trong SDRAM
    reg [1:0] clk_div;
    always @(posedge clk_50 or negedge rst_n) begin
        if (!rst_n) begin
            clk_div  <= 2'd0;
            CAM_PCLK <= 1'b0;
        end else begin
            clk_div <= clk_div + 1'b1;
            if (clk_div == 2'd1) begin
                CAM_PCLK <= ~CAM_PCLK;
            end
        end
    end

    // 2. Định nghĩa các thông số cấu trúc thời gian (Timing Parameters)
    // 640 pixels chủ động hiển thị tương đương 1280 chu kỳ PCLK (Mỗi pixel = 2 bytes)
    parameter H_ACTIVE   = 11'd1280; 
    parameter H_BLANK    = 11'd320;  
    parameter H_TOTAL    = 11'd1600; // Tổng số xung PCLK trên một dòng quét
    
    parameter V_ACTIVE   = 10'd480;  
    parameter V_BLANK    = 10'd20;   
    parameter V_TOTAL    = 10'd500;  // Tổng số dòng quét trên một khung hình

    reg [10:0] h_cnt;
    reg [9:0]  v_cnt;

    // Bộ đếm quét tọa độ không gian ảnh chạy theo xung PCLK giả lập
    always @(posedge CAM_PCLK or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 11'd0;
            v_cnt <= 10'd0;
        end else begin
            if (h_cnt == (H_TOTAL - 1'b1)) begin
                h_cnt <= 11'd0;
                if (v_cnt == (V_TOTAL - 1'b1))
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    // 3. Xây dựng mẫu thử nghiệm thanh màu (Test Pattern) hệ YUV Full-Range
    // Chia màn hình làm 4 cột màu đứng bằng nhau dọc theo trục h_cnt (mỗi cột rộng 320 PCLK)
    reg [7:0] active_y;
    reg [7:0] active_u;
    reg [7:0] active_v;

    always @(*) begin
        if (h_cnt < 11'd320) begin          // Cột 1: Màu ĐỎ (Red)
            active_y = 8'd76;
            active_u = 8'd85;
            active_v = 8'd255;
        end else if (h_cnt < 11'd640) begin   // Cột 2: Màu XANH LÁ (Green)
            active_y = 8'd150;
            active_u = 8'd44;
            active_v = 8'd21;
        end else if (h_cnt < 11'd960) begin   // Cột 3: Màu XANH DƯƠNG (Blue)
            active_y = 8'd29;
            active_u = 8'd255;
            active_v = 8'd107;
        end else begin                      // Cột 4: Màu TRẮNG (White)
            active_y = 8'd255;
            active_u = 8'd128;
            active_v = 8'd128; // 128 là giá trị trung tính triệt tiêu màu
        end
    end

    // 4. Đồng bộ hóa xuất dữ liệu ngõ ra bằng tầng đăng ký (Registered Outputs)
    // Thiết kế này đảm bảo các tín hiệu điều khiển và data đổi trạng thái cùng một thời điểm,
    // loại bỏ hoàn toàn việc lệch 1 pixel ở đầu dòng quét của module capture.
    always @(posedge CAM_PCLK or negedge rst_n) begin
        if (!rst_n) begin
            CAM_HREF  <= 1'b0;
            CAM_VSYNC <= 1'b0;
            CAM_DATA  <= 8'd0;
        end else begin
            // Sinh tín hiệu điều khiển đồng bộ
            CAM_HREF  <= (v_cnt < V_ACTIVE) && (h_cnt < H_ACTIVE);
            CAM_VSYNC <= (v_cnt >= 10'd482) && (v_cnt <= 10'd484); // VSYNC nhô cao trong vùng Blank

            // Ép dữ liệu chạy theo trật tự chuỗi byte YUYV nghiêm ngặt
            if ((v_cnt < V_ACTIVE) && (h_cnt < H_ACTIVE)) begin
                if (h_cnt[0] == 1'b0) begin
                    CAM_DATA <= active_y;  // Cứ chu kỳ PCLK chẵn (0, 2, 4...) xuất Độ sáng Y
                end else begin
                    if (h_cnt[1] == 1'b0)
                        CAM_DATA <= active_u; // Chu kỳ lẻ dạng 1, 5, 9... xuất Cb (U)
                    else
                        CAM_DATA <= active_v; // Chu kỳ lẻ dạng 3, 7, 11... xuất Cr (V)
                end
            end else begin
                CAM_DATA <= 8'd0; // Nằm ngoài vùng tích cực thì trả về mức nền đen
            end
        end
    end

endmodule