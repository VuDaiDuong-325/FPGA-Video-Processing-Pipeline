module sdram_double_buffer_controller (
    input wire clk,                 // Clock hệ thống (50 MHz - nối chung với Nios II)
    input wire rst_n,
    input wire cam_vsync,           // Phát hiện cạnh để đảo tầng đệm
    
    // Giao tiếp với Video DCFIFO (Chế độ Show-Ahead)
    input  wire        fifo_empty,  // Cờ báo FIFO rỗng (nối với !rdempty)
    output reg         fifo_rdreq,  // Lệnh đọc FIFO
    input  wire [15:0] fifo_q,      // Dữ liệu từ FIFO ra (ở chế độ Show-Ahead dữ liệu có sẵn tại đây)
    
    // Giao tiếp Avalon Master nối vào SDRAM Controller trong Qsys
    output reg [24:0] avm_address,   // Địa chỉ WORD gửi tới SDRAM
    output reg [15:0] avm_writedata, // Dữ liệu pixel ghi vào SDRAM
    output reg        avm_write,     // Lệnh ghi Avalon
    input  wire       avm_waitrequest // Chân phản hồi báo bận từ SDRAM
);
    // Định nghĩa địa chỉ nền của 2 tầng đệm (Địa chỉ dạng WORD)
    // Khung hình VGA 640x480 = 307,200 Words.
    localparam BUFFER_A_BASE = 25'h1000_000; 
    localparam BUFFER_B_BASE = 25'h104_B000; // 307,200 tương đương 0x4B000 trong hệ Hex
    localparam MAX_PIXELS    = 19'd3072;

    reg current_buffer;      // 0: Ghi vào A | 1: Ghi vào B
    reg [18:0] pixel_counter; // Bộ đếm vị trí pixel từ 0 đến 307199
    
    // Mạch bắt cạnh xuống của VSYNC để đổi buffer
    reg [2:0] vsync_sync_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) vsync_sync_reg <= 3'b0;
        else        vsync_sync_reg <= {vsync_sync_reg[1:0], cam_vsync};
    end
    wire frame_done = (vsync_sync_reg[2] == 1'b1 && vsync_sync_reg[1] == 1'b0);

    // Xác định địa chỉ nền dựa trên tầng đệm hiện tại
    wire [24:0] base_addr = (current_buffer == 1'b0) ? BUFFER_A_BASE : BUFFER_B_BASE;

    // Định nghĩa các trạng thái của FSM
    localparam ST_IDLE  = 1'b0;
    localparam ST_WRITE = 1'b1;
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_buffer <= 1'b0;
            pixel_counter  <= 19'd0;
            state          <= ST_IDLE;
            avm_write      <= 1'b0;
            fifo_rdreq     <= 1'b0;
            avm_address    <= 25'd0;
            avm_writedata  <= 16'd0;
        end else begin
            // Đảo tầng đệm (Ping-Pong Switch) khi kết thúc khung hình
            if (frame_done) begin
                current_buffer <= ~current_buffer;
                pixel_counter  <= 19'd0;
            end

            case (state)
                ST_IDLE: begin
                    fifo_rdreq <= 1'b0;
                    
                    // Nếu FIFO có dữ liệu, chưa hết khung hình, và SDRAM không bận
                    if (!fifo_empty && pixel_counter < MAX_PIXELS && !avm_waitrequest) begin
                        avm_write     <= 1'b1;
                        avm_writedata <= fifo_q; // Chốt dữ liệu hợp lệ từ cổng Show-Ahead FIFO
                        avm_address   <= base_addr + pixel_counter;
                        
                        fifo_rdreq    <= 1'b1;   // Nháy cờ đọc để yêu cầu FIFO chuyển sang từ tiếp theo
                        state         <= ST_WRITE;
                    end
                end
                
                ST_WRITE: begin
                    fifo_rdreq <= 1'b0; // Hạ cờ đọc ngay lập tức ở chu kỳ tiếp theo (chỉ nháy 1 xung)
                    
                    // Đợi cho đến khi SDRAM rảnh và chấp nhận xong chu kỳ ghi hiện tại
                    if (!avm_waitrequest) begin
                        avm_write     <= 1'b0; // Tắt lệnh ghi
                        pixel_counter <= pixel_counter + 1'b1; // Tăng bộ đếm pixel
                        
                        // QUAY VỀ ST_IDLE: Tạo khoảng nghỉ 1 chu kỳ clock để cổng 'fifo_q' 
                        // của Show-Ahead FIFO kịp cập nhật dữ liệu của pixel tiếp theo.
                        state         <= ST_IDLE;
                    end
                    // Nếu avm_waitrequest == 1, FSM sẽ đứng im tại ST_WRITE này, 
                    // giữ nguyên avm_write=1, avm_address và avm_writedata theo đúng luật Avalon-MM.
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule