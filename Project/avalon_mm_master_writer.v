module avalon_mm_master_writer #(
    parameter ADDR_WIDTH = 32, 
    parameter DATA_WIDTH = 16  
)(
    input  wire                   clk_i,
    input  wire                   rst_i,
		
    // Read-Port DC_FIFO
    input  wire                   fifo_empty_i,
    input  wire [DATA_WIDTH-1:0]  fifo_dout_i,
    output reg                    fifo_re_o,
    
    // Đồng bộ khung hình Camera
    input  wire                   vsync_i, 
    
    // AMM Write
    output reg  [ADDR_WIDTH-1:0]  amm_address_o,
    output reg                    amm_write_o,
    output reg  [DATA_WIDTH-1:0]  amm_writedata_o,
    input  wire                   amm_waitrequest_i,

    // [PING-PONG]: Chân xuất báo Bank đang ghi ra ngoài
    output wire                   write_bank_o
);

    localparam STATE_IDLE   = 2'd0;
    localparam STATE_READ   = 2'd1;
    localparam STATE_WRITE  = 2'd2;
	
    reg [1:0]            state_r;
    reg                  vsync_d1_r;
    wire                 vsync_rising_edge_w = (vsync_i == 1'b1 && vsync_d1_r == 1'b0);
	
    // Thanh ghi quản lý Ping-Pong
    reg                  write_bank_r; // 0: đang ghi Bank 0, 1: đang ghi Bank 1
    reg [ADDR_WIDTH-1:0] offset_r;     // Độ lệch chạy từ 0 -> 614398

    assign write_bank_o = write_bank_r;

    // Tự động tính toán địa chỉ tuyệt đối dựa trên Bank và Offset
    always @(*) begin
        amm_address_o = offset_r + (write_bank_r ? 32'd614400 : 32'd0);
    end
	
    always @(posedge clk_i) begin 
        if (rst_i) begin
            fifo_re_o        <= 1'd0;
            amm_write_o      <= 1'd0;
            amm_writedata_o  <= {DATA_WIDTH{1'b0}};
            vsync_d1_r       <= 1'd0;
            write_bank_r     <= 1'b0;
            offset_r         <= {ADDR_WIDTH{1'b0}};
            state_r          <= STATE_IDLE;
        end 
        else begin
            vsync_d1_r <= vsync_i;
			
            if (vsync_rising_edge_w) begin // Camera bắt đầu khung hình mới
                offset_r     <= {ADDR_WIDTH{1'b0}};
                write_bank_r <= ~write_bank_r; // Đảo qua Bank kia để ghi khung hình mới
                state_r      <= STATE_IDLE;
            end 
            else begin
                case (state_r)
                    STATE_IDLE: begin
                        amm_write_o <= 1'd0;
                        if (!fifo_empty_i && !amm_waitrequest_i) begin
                            fifo_re_o <= 1'b1;
                            state_r   <= STATE_READ;
                        end else
                            fifo_re_o <= 1'b0;
                    end
                    STATE_READ: begin
                        fifo_re_o       <= 1'b0;
                        amm_writedata_o <= fifo_dout_i;
                        amm_write_o     <= 1'b1;
                        state_r         <= STATE_WRITE;
                    end
                    STATE_WRITE: begin
                        if (!amm_waitrequest_i) begin
                            amm_write_o <= 1'b0;
                            
                            // Tăng offset nội bộ bên trong khung hình
                            if (offset_r < 32'd614398)
                                offset_r <= offset_r + 32'd2;
                            else
                                offset_r <= {ADDR_WIDTH{1'b0}}; // Tràn khung hình, đợi VSYNC giải phóng
                                
                            state_r <= STATE_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule