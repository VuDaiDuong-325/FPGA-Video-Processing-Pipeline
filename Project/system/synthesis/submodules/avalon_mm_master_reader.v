module avalon_mm_master_reader # (
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16
)(
    input  wire                   clk_i,       // Clock hệ thống (50MHz)
    input  wire                   rst_i,       // Reset active high
    
    // Ghi vào DC_FIFO hiển thị
    output reg                    fifo_we_o,
    output reg  [DATA_WIDTH-1:0]  fifo_din_o,
    input  wire                   fifo_full_i, 
    
    // Đồng bộ khung hình từ miền VGA
    input  wire                   vga_vsync_i, 
    
    // Giao tiếp Avalon-MM Master Read
    output reg  [ADDR_WIDTH-1:0]  amm_address_o,
    output reg                    amm_read_o,
    input  wire [DATA_WIDTH-1:0]  amm_readdata_i,
    input  wire                   amm_readdatavalid_i,
    input  wire                   amm_waitrequest_i,

    // [PING-PONG]: Nhận tín hiệu Bank từ khối ghi truyền sang
    input  wire                   write_bank_i
);

    localparam STATE_IDLE      = 2'd0;
    localparam STATE_WAIT_REQ  = 2'd1;
    localparam STATE_WAIT_DATA = 2'd2;

    reg [1:0]            state_r;
    reg                  vga_vsync_d1_r;
    wire                 vga_vsync_rising_w = (vga_vsync_i == 1'b1 && vga_vsync_d1_r == 1'b0);
    
    // Thanh ghi quản lý Ping-Pong phía đọc
    reg                  read_bank_r;
    reg [ADDR_WIDTH-1:0] offset_r;

    // Tự động tính toán địa chỉ tuyệt đối để đọc SDRAM
    always @(*) begin
        amm_address_o = offset_r + (read_bank_r ? 32'd614400 : 32'd0);
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            vga_vsync_d1_r  <= 1'b0;
            read_bank_r     <= 1'b0;
            offset_r        <= {ADDR_WIDTH{1'b0}};
            amm_read_o      <= 1'b0;
            fifo_we_o       <= 1'b0;
            fifo_din_o      <= {DATA_WIDTH{1'b0}};
            state_r         <= STATE_IDLE;
        end 
        else begin
            vga_vsync_d1_r <= vga_vsync_i;
            
            if (vga_vsync_rising_w) begin // VGA bắt đầu một khung hình quét mới
                offset_r    <= {ADDR_WIDTH{1'b0}};
                // ĐỌC bank mà Camera KHÔNG ghi (bank đã hoàn thiện)
                read_bank_r <= ~write_bank_i; 
                state_r     <= STATE_IDLE;
                amm_read_o  <= 1'b0;
            end 
            else begin
                fifo_we_o <= 1'b0; // Mặc định tắt ghi FIFO

                case (state_r)
                    STATE_IDLE: begin
                        if (!fifo_full_i) begin
                            amm_read_o <= 1'b1;
                            state_r    <= STATE_WAIT_REQ;
                        end
                    end

                    STATE_WAIT_REQ: begin
                        if (!amm_waitrequest_i) begin
                            amm_read_o <= 1'b0;
                            state_r    <= STATE_WAIT_DATA;
                        end
                    end

                    STATE_WAIT_DATA: begin
                        if (amm_readdatavalid_i) begin
                            fifo_we_o  <= 1'b1;
                            fifo_din_o <= amm_readdata_i;
                            
                            if (offset_r < 32'd614398)
                                offset_r <= offset_r + 32'd2;
                            else
                                offset_r <= {ADDR_WIDTH{1'b0}}; // Tràn khung hình, đợi VSYNC reset
                                
                            state_r    <= STATE_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule