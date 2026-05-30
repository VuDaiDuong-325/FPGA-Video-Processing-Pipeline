module sdram_read_controller (
    input wire clk,                 // Xung nhịp hệ thống (CLOCK_50)
    input wire rst_n,               // Reset tích cực mức thấp

    // Đồng bộ khung hình (Từ mạch ghi / Camera)
    input wire frame_done,          // Xung kết thúc 1 khung hình (1 chu kỳ clock)

    // Giao tiếp Avalon-MM Master (Đọc từ SDRAM)
    output reg [24:0] avm_address,       // Địa chỉ đọc (Word address)
    output reg        avm_read,          // Lệnh phát yêu cầu đọc
    input  wire       avm_waitrequest,   // SDRAM báo bận
    input  wire [15:0] avm_readdata,     // Dữ liệu YUV422 trả về từ SDRAM
    input  wire       avm_readdatavalid, // Tín hiệu báo dữ liệu trả về hợp lệ

    // Giao tiếp với VGA DCFIFO (Ghi vào FIFO)
    output wire        fifo_wrreq,       // Yêu cầu ghi vào FIFO
    output wire [15:0] fifo_wrdata,      // Dữ liệu ghi vào FIFO
    input  wire [10:0]  fifo_wrusedw      // Mức chứa hiện tại của FIFO (Độ sâu FIFO là 2048)
);

    // =========================================================================
    // THÔNG SỐ CẤU HÌNH BỘ NHỚ
    // =========================================================================
    localparam BUFFER_A_BASE = 25'h1000_000;
    localparam BUFFER_B_BASE = 25'h104_B000; // 307,200 Words
    localparam MAX_PIXELS    = 19'd307_200;  // 640 x 480

    // Biến trạng thái nội bộ
    reg read_buffer_sel; // 0: Đọc từ Buffer A | 1: Đọc từ Buffer B
    reg [18:0] req_cnt;  // Bộ đếm số lượng pixel đã gửi yêu cầu đọc
	 reg frame_ready; // Cờ: đã có ít nhất 1 frame trong SDRAM chưa?

    // =========================================================================
    // 1. QUẢN LÝ ĐỆM KÉP (PING-PONG)
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Giả sử mạch ghi khởi động ở Buffer A (0), mạch Đọc PHẢI ở Buffer B (1)
            read_buffer_sel <= 1'b1;
				frame_ready <= 1'b0;
        end else if (frame_done) begin
            // Lật đệm mỗi khi Camera báo xong một khung hình
            read_buffer_sel <= ~read_buffer_sel;
				frame_ready <= 1'b1;
        end
    end

    wire [24:0] base_addr = (read_buffer_sel == 1'b0) ? BUFFER_A_BASE : BUFFER_B_BASE;

    // =========================================================================
    // 2. LOGIC PHÁT LỆNH ĐỌC CẤP TỐC (PIPELINED READ) & CHỐNG TRÀN FIFO
    // =========================================================================
    // * GIẢI THÍCH FLOW CONTROL: 
    // SDRAM có độ trễ. Khi ta phát lệnh đọc, phải mất vài chu kỳ dữ liệu mới về.
    // Nếu ta đợi FIFO đầy 100% (wrfull) mới dừng đọc, thì những dữ liệu "đang lơ lửng" 
    // trên đường về sẽ làm tràn FIFO và mất dữ liệu.
    // -> Giải pháp: Dừng đọc khi FIFO đạt ngưỡng an toàn
	 // FIFO sâu 2048. Ta cho phép đọc khi FIFO chứa ít hơn 1536 từ.
    // Dư ra 512 từ trống để hứng dữ liệu trễ từ SDRAM về.
    wire safe_to_read = (fifo_wrusedw < 11'd1536); 
    wire need_to_read = (req_cnt < MAX_PIXELS);
    wire can_read     = safe_to_read && need_to_read && frame_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_cnt     <= 19'd0;
            avm_read    <= 1'b0;
            avm_address <= 25'd0;
        end else begin
            // ƯU TIÊN SỐ 1: BẢO VỆ BUS AVALON
            if (avm_read && avm_waitrequest) begin
                avm_read    <= avm_read;
                avm_address <= avm_address;
            end 
            // ƯU TIÊN SỐ 2: RESET KHI XONG KHUNG HÌNH
            else if (frame_done) begin
                req_cnt  <= 19'd0;
                avm_read <= 1'b0;
            end 
            // ƯU TIÊN SỐ 3: PHÁT LỆNH ĐỌC MỚI
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

    // =========================================================================
    // 3. LOGIC NHẬN DỮ LIỆU TỪ SDRAM VÀ BƠM VÀO FIFO
    // =========================================================================
    // Tín hiệu avm_readdatavalid tự động đồng bộ hoàn hảo với luồng dữ liệu trả về.
    // Ta đấu trực tiếp nó vào chân "yêu cầu ghi" (wrreq) của FIFO.
    assign fifo_wrreq  = avm_readdatavalid;
    assign fifo_wrdata = avm_readdata;

endmodule