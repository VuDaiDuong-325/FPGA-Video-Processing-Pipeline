module sdram_double_buffer_controller (
    input wire clk,                 // Clock hệ thống (50 MHz - nối chung với Nios II)
    input wire rst_n,
    
    // Tín hiệu từ Camera
    input wire cam_vsync,           // Phát hiện cạnh để đảo tầng đệm
    input wire cam_pixel_valid,     // Lệnh ghi pixel từ FIFO (chính là !rdempty của FIFO)
    input wire [15:0] cam_pixel_data,
    
    // Giao tiếp Avalon Master nối vào SDRAM Controller trong Qsys
    output reg [24:0] avm_address,   // ĐỊA CHỈ WORD gửi tới SDRAM
    output reg [15:0] avm_writedata, // Dữ liệu pixel ghi vào SDRAM
    output reg avm_write,            // Lệnh ghi Avalon
    input wire avm_waitrequest       // Chân phản hồi từ SDRAM báo bận
);

    // Định nghĩa địa chỉ nền của 2 tầng đệm (Địa chỉ dạng WORD)
    // Khung hình VGA 640x480 = 307,200 Words.
    localparam BUFFER_A_BASE = 25'h0000_000; 
    localparam BUFFER_B_BASE = 25'h004_B000; // 307,200 tương đương 0x4B000 trong hệ Hex

    reg current_buffer; // 0: Ghi vào A (VGA đọc B) | 1: Ghi vào B (VGA đọc A)
    reg [18:0] pixel_counter; // Bộ đếm vị trí pixel từ 0 đến 307199
    
    // Mạch bắt cạnh xuống của VSYNC để đổi buffer
    reg [2:0] vsync_sync_reg;
	 always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			vsync_sync_reg <= 3'b0;
		end else begin
			// Dịch bit liên tục để đẩy tín hiệu qua các tầng Flip-Flop
			vsync_sync_reg <= {vsync_sync_reg[1:0], cam_vsync};
		end
	 end

	 // Phát hiện cạnh xuống (Falling Edge) dựa trên 2 tầng đã được đồng bộ an toàn:
	 // vsync_sync_reg[1] là giá trị hiện tại (đã qua 2 tầng FF)
	 // vsync_sync_reg[2] là giá trị của chu kỳ trước đó (đã qua 3 tầng FF)
	 wire frame_done = (vsync_sync_reg[2] == 1'b1 && vsync_sync_reg[1] == 1'b0);

    // Logic Đảo Tầng Đệm (Ping-Pong Switch)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_buffer <= 1'b0;
        end else if (frame_done) begin
            current_buffer <= ~current_buffer;
        end
    end

    // Quản lý sinh địa chỉ ghi tuần tự vào SDRAM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_counter <= 19'd0;
            avm_address   <= 25'd0;
            avm_write     <= 1'b0;
            avm_writedata <= 16'd0;
        end else begin
            if (frame_done) begin
                pixel_counter <= 19'd0; // Hết khung hình thì reset bộ đếm
            end else if (cam_pixel_valid && !avm_waitrequest) begin
                // TÍNH ĐỊA CHỈ WORD (Không dịch bit << 1 nữa)
                if (current_buffer == 1'b0)
                    avm_address <= BUFFER_A_BASE + pixel_counter;
                else
                    avm_address <= BUFFER_B_BASE + pixel_counter;

                avm_writedata <= cam_pixel_data;
                avm_write     <= 1'b1;
                
                // Tăng tiến địa chỉ pixel
                if (pixel_counter < 19'd307199)
                    pixel_counter <= pixel_counter + 1'b1;
                else
                    pixel_counter <= 19'd0;
            end else if (!avm_waitrequest) begin
                avm_write <= 1'b0; // Hạ lệnh ghi nếu không có dữ liệu mới hoặc SDRAM bận
            end
        end
    end

endmodule