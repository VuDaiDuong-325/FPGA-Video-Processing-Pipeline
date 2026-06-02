module vga_fifo_test_generator (
    input wire clk,                  
    input wire rst_n,                
    input wire vga_vsync,            
    input wire [10:0] fifo_wrusedw,  
    
    output reg        fifo_wrreq,    
    output reg [15:0] fifo_wrdata    
);

    localparam MAX_PIXELS = 19'd307_200; 

    reg [18:0] pixel_cnt;            
    reg [9:0]  x_cnt;

    wire safe_to_write = (fifo_wrusedw < 11'd1536);
    wire need_to_write = (pixel_cnt < MAX_PIXELS);

    // Đồng bộ tín hiệu vga_vsync (đang ở miền 25MHz) sang miền xung nhịp clk (50MHz) an toàn
    reg vsync_d1, vsync_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_d1 <= 1'b1;
            vsync_d2 <= 1'b1;
        end else begin
            vsync_d1 <= vga_vsync;
            vsync_d2 <= vsync_d1;
        end
    end

    reg [7:0] sample_y, sample_cb, sample_cr;

    // Bảng màu YUV (Sử dụng x_cnt độc lập)
    always @(*) begin
        if (x_cnt < 80) begin
            sample_y = 8'd235; sample_cb = 8'd128; sample_cr = 8'd128; // Trắng
        end else if (x_cnt < 160) begin
            sample_y = 8'd210; sample_cb = 8'd16;  sample_cr = 8'd146; // Vàng
        end else if (x_cnt < 240) begin
            sample_y = 8'd170; sample_cb = 8'd166; sample_cr = 8'd16;  // Cyan
        end else if (x_cnt < 320) begin
            sample_y = 8'd145; sample_cb = 8'd54;  sample_cr = 8'd34;  // Xanh lá
        end else if (x_cnt < 400) begin
            sample_y = 8'd106; sample_cb = 8'd202; sample_cr = 8'd222; // Tím
        end else if (x_cnt < 480) begin
            sample_y = 8'd81;  sample_cb = 8'd90;  sample_cr = 8'd240; // Đỏ
        end else if (x_cnt < 560) begin
            sample_y = 8'd41;  sample_cb = 8'd240; sample_cr = 8'd110; // Xanh dương
        end else begin
            sample_y = 8'd16;  sample_cb = 8'd128; sample_cr = 8'd128; // Đen
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_cnt   <= 19'd0;
            x_cnt       <= 10'd0;
            fifo_wrreq  <= 1'b0;
            fifo_wrdata <= 16'd0;
            
        end else if (!vsync_d2) begin // <--- KHI VGA_VSYNC XUỐNG MỨC THẤP
            // QUAN TRỌNG: Reset và "ngủ đông" chờ FIFO được súc rửa sạch sẽ
            pixel_cnt   <= 19'd0;
            x_cnt       <= 10'd0;
            fifo_wrreq  <= 1'b0;
            
        end else if (safe_to_write && need_to_write) begin
            fifo_wrreq <= 1'b1;
            // Nạp tuần tự đúng chuẩn YUV 4:2:2 để không bị đảo màu
            if (!x_cnt[0]) fifo_wrdata <= {sample_cb, sample_y}; // Pixel chẵn
            else           fifo_wrdata <= {sample_cr, sample_y}; // Pixel lẻ
            
            pixel_cnt <= pixel_cnt + 1'b1;
            if (x_cnt == 10'd639) x_cnt <= 10'd0;
            else                  x_cnt <= x_cnt + 1'b1;
            
        end else begin
            fifo_wrreq <= 1'b0;
        end
    end

endmodule