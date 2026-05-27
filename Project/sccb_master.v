module sccb_master (
    input wire clk_i,        // Clock hệ thống 50MHz từ Board
    input wire rst_n_i,      // Reset tích cực thấp
    input wire start_i,      // Xung kích hoạt bắt đầu truyền (1 chu kỳ clk)
    input wire [7:0] reg_addr_i,  // Địa chỉ thanh ghi cần ghi
    input wire [7:0] reg_data_i,  // Dữ liệu cần ghi vào thanh ghi
    output reg ready_o,      // Báo trạng thái rảnh (1: Sẵn sàng nhận lệnh mới)
    output reg sioc_o,       // Chân xung nhịp SCCB Clock nối ra Camera
    inout wire siod_io       // Chân dữ liệu SCCB Data (Bi-directional)
);

    // Xử lý chân InOut (Tri-state Buffer) cho SIOD
    reg siod_oe;
    reg siod_out;
    assign siod_io = siod_oe ? siod_out : 1'bZ;

    // Bộ chia xung tạo Ticks 400KHz (50,000,000 / 400,000 = 125)
    reg [7:0] clk_div_r;
    wire tick_w = (clk_div_r == 8'd124);
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) clk_div_r <= 0;
        else if (tick_w) clk_div_r <= 0;
        else clk_div_r <= clk_div_r + 1'b1;
    end

    // Các trạng thái của máy trạng thái (FSM)
    localparam ST_IDLE  = 3'd0;
    localparam ST_START = 3'd1;
    localparam ST_DATA  = 3'd2;
    localparam ST_ACK   = 3'd3;
    localparam ST_STOP  = 3'd4;

    reg [2:0] state_r;
    reg [1:0] sub_step_r; // Chia nhỏ 1 bit thành 4 phân đoạn (0,1,2,3)
    reg [3:0] bit_cnt_r;   // Đếm từ bit 7 về bit 0
    reg [1:0] byte_cnt_r;  // Đếm byte (0: Device ID, 1: Reg Addr, 2: Reg Data)
    reg [7:0] shift_reg_r; // Thanh ghi dịch dữ liệu

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r     <= ST_IDLE;
            sub_step_r  <= 0;
            bit_cnt_r   <= 0;
            byte_cnt_r  <= 0;
            shift_reg_r <= 0;
            ready_o     <= 1'b1;
            sioc_o      <= 1'b1;
            siod_oe     <= 1'b1;
            siod_out    <= 1'b1;
        end else if (tick_w) begin
            sub_step_r <= sub_step_r + 1'b1; // Mặc định tăng phân đoạn sau mỗi tick
            
            case (state_r)
                ST_IDLE: begin
                    ready_o    <= 1'b1;
                    sioc_o     <= 1'b1;
                    siod_oe    <= 1'b1;
                    siod_out   <= 1'b1;
                    sub_step_r <= 0;
                    if (start_i) begin
                        state_r    <= ST_START;
                        ready_o    <= 1'b0;
                        byte_cnt_r <= 0;
                    end
                end

                ST_START: begin
                    // Điều kiện START: SIOD kéo xuống thấp trong khi SIOC vẫn cao
                    case (sub_step_r)
                        2'd0: begin sioc_o <= 1'b1; siod_out <= 1'b1; end
                        2'd1: begin sioc_o <= 1'b1; siod_out <= 1'b0; end // SIOD xuống trước
                        2'd2: begin sioc_o <= 1'b1; siod_out <= 1'b0; end
                        2'd3: begin 
                            sioc_o      <= 1'b0; // SIOC xuống sau
                            state_r     <= ST_DATA;
                            bit_cnt_r   <= 4'd7;
                            sub_step_r  <= 0;
                            shift_reg_r <= 8'h42; // Nạp ID ghi mặc định của OV7670
                        end
                    endcase
                end

                ST_DATA: begin
                    siod_oe <= 1'b1; // Master lái đường truyền dữ liệu
                    case (sub_step_r)
                        2'd0: begin
                            sioc_o   <= 1'b0;
                            siod_out <= shift_reg_r[bit_cnt_r]; // Thay đổi bit khi SIOC mức thấp
                        end
                        2'd1: begin
                            sioc_o   <= 1'b1; // Kéo SIOC lên cao để Camera chốt dữ liệu
                        end
                        2'd2: begin
                            sioc_o   <= 1'b1;
                        end
                        2'd3: begin
                            sioc_o   <= 1'b0;
                            sub_step_r <= 0;
                            if (bit_cnt_r == 0) begin
                                state_r <= ST_ACK;
                            end else begin
                                bit_cnt_r <= bit_cnt_r - 1'b1;
                            end
                        end
                    endcase
                end

                ST_ACK: begin
                    // SCCB Không quan tâm bit ACK (Don't care), chỉ cần thả nổi dây SIOD
                    case (sub_step_r)
                        2'd0: begin sioc_o <= 1'b0; siod_oe <= 1'b0; end // Thả nổi chân SIOD
                        2'd1: begin sioc_o <= 1'b1; end
                        2'd2: begin sioc_o <= 1'b1; end
                        2'd3: begin
                            sioc_o     <= 1'b0;
                            sub_step_r <= 0;
                            if (byte_cnt_r == 2'd2) begin // Đã gửi xong cả 3 byte
                                state_r <= ST_STOP;
                            end else begin
                                state_r    <= ST_DATA;
                                byte_cnt_r <= byte_cnt_r + 1'b1;
                                bit_cnt_r  <= 4'd7;
                                // Nạp Byte tiếp theo vào thanh ghi dịch
                                if (byte_cnt_r == 2'd0) shift_reg_r <= reg_addr_i;
                                else if (byte_cnt_r == 2'd1) shift_reg_r <= reg_data_i;
                            end
                        end
                    endcase
                end

                ST_STOP: begin
                    // Điều kiện STOP: SIOD kéo từ thấp lên cao trong khi SIOC đang cao
                    case (sub_step_r)
                        2'd0: begin sioc_o <= 1'b0; siod_oe <= 1'b1; siod_out <= 1'b0; end
                        2'd1: begin sioc_o <= 1'b1; siod_out <= 1'b0; end // SIOC lên trước
                        2'd2: begin sioc_o <= 1'b1; siod_out <= 1'b1; end // SIOD lên sau -> Tạo điều kiện STOP
                        2'd3: begin
                            state_r    <= ST_IDLE;
                            sub_step_r <= 0;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule