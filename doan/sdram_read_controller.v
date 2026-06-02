module sdram_read_controller (
    input wire clk,                 // Xung nhịp hệ thống (CLOCK_50)
    input wire rst_n,               // Reset tích cực mức thấp

    // TÁCH BIỆT ĐỒNG BỘ HAI ĐẦU GHI/ĐỌC
    input wire cam_frame_done,      // Xung kết thúc khung hình phía CAMERA (15.6Hz) -> Dùng để đổi tầng đệm
    input wire vga_frame_done,      // Xung kết thúc khung hình phía VGA (60Hz)    -> Dùng để reset bộ đếm

    // Giao tiếp Avalon-MM Master (Đọc từ SDRAM)
    output reg [24:0] avm_address,       
    output reg        avm_read,          
    input  wire       avm_waitrequest,   
    input  wire [15:0] avm_readdata,     
    input  wire       avm_readdatavalid, 

    // Giao tiếp với VGA DCFIFO
    output wire        fifo_wrreq,       
    output wire [15:0] fifo_wrdata,      
    input  wire [10:0] fifo_wrusedw      
);

    // THÔNG SỐ CẤU HÌNH BỘ NHỚ
    localparam BUFFER_A_BASE = 25'h1000_000;
    localparam BUFFER_B_BASE = 25'h104_B000; 
    localparam MAX_PIXELS    = 19'd307_200; // 640 x 480 

    reg read_buffer_sel; // 0: Đọc Buffer A | 1: Đọc Buffer B 
    reg [18:0] req_cnt;  // Bộ đếm số lượng pixel đã gửi yêu cầu đọc
    reg frame_ready;     // Cờ báo đã có ít nhất 1 frame hoàn chỉnh

    // =========================================================================
    // 1. QUẢN LÝ ĐỆM KÉP (PING-PONG) - CHẠY THEO KHUNG HÌNH CAMERA
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_buffer_sel <= 1'b1; // Khởi tạo lệch pha với bộ Ghi để tránh đụng độ
            frame_ready     <= 1'b0; 
        end else if (cam_frame_done) begin
            // CHỈ đổi tầng đệm đọc khi Camera thực sự ghi xong 1 frame hoàn chỉnh
            read_buffer_sel <= ~read_buffer_sel;
            frame_ready     <= 1'b1; 
        end
    end

    wire [24:0] base_addr = (read_buffer_sel == 1'b0) ? BUFFER_A_BASE : BUFFER_B_BASE;

    // =========================================================================
    // 2. LOGIC PHÁT LỆNH ĐỌC & RESET ĐỊA CHỈ - CHẠY THEO KHUNG HÌNH VGA
    // =========================================================================
    wire safe_to_read = (fifo_wrusedw < 11'd1536);
    wire need_to_read = (req_cnt < MAX_PIXELS);
    wire can_read     = safe_to_read && need_to_read && frame_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_cnt     <= 19'd0;
            avm_read    <= 1'b0; 
            avm_address <= 25'd0; 
        end else begin
            // ƯU TIÊN SỐ 1: BẢO VỆ BUS AVALON (Khi Bus bận phải giữ nguyên trạng thái)
            if (avm_read && avm_waitrequest) begin
                avm_read    <= avm_read;
                avm_address <= avm_address; 
            end 
            // ƯU TIÊN SỐ 2: RESET BỘ ĐẾM KHI QUÉT XONG 1 KHUNG HÌNH VGA (60Hz)
            else if (vga_frame_done) begin
                req_cnt  <= 19'd0; // Ép bộ đọc quay về pixel đầu tiên để màn hình không bị lệch dòng [cite: 21]
                avm_read <= 1'b0; 
            end 
            // ƯU TIÊN SỐ 3: PHÁT LỆNH ĐỌC TUẦN TỰ
            else begin
                if (can_read) begin
                    avm_read    <= 1'b1; 
                    avm_address <= base_addr + req_cnt;
                    req_cnt     <= req_cnt + 1'b1;
                end else begin
                    avm_read    <= 1'b0; 
                end
            end
        end
    end

    // Ghi dữ liệu trực tiếp vào VGA FIFO khi Bus trả về dữ liệu hợp lệ
    assign fifo_wrreq  = avm_readdatavalid; 
    assign fifo_wrdata = avm_readdata;

endmodule