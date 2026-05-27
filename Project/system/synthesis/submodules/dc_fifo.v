module dc_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write signals (Mien wr_clk)
    input  wire                  wr_clk_i,
    input  wire                  wr_rst_i,
    input  wire                  we_i,
    input  wire [DATA_WIDTH-1:0] din_i,
    output reg                   full_o,

    // Read signals (Mien rd_clk)
    input  wire                  rd_clk_i,
    input  wire                  rd_rst_i,
    input  wire                  re_i,
    output reg  [DATA_WIDTH-1:0] dout_o,
    output reg                   empty_o
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    // Bo nho RAM
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem_r [0:DEPTH-1];

    // Con tro Binary trong cac thanh ghi (Reg)
    reg [ADDR_WIDTH:0] wr_ptr_bin_r;
    reg [ADDR_WIDTH:0] rd_ptr_bin_r;

    // Con tro Gray trong cac thanh ghi (Reg) - DE TRU KHOI GLITCH
    reg [ADDR_WIDTH:0] wr_ptr_gray_r;
    reg [ADDR_WIDTH:0] rd_ptr_gray_r;

    // Tin hieu day (Wire) chua gia tri tinh toan tiep theo (_w)
    wire [ADDR_WIDTH:0] wr_ptr_bin_next_w;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next_w;
    
    // Tin hieu day (Wire) lay tu ngo ra cua module bin_to_gray (_w)
    wire [ADDR_WIDTH:0] wr_ptr_gray_next_w;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next_w;

    // Tin hieu day (Wire) lay tu ngo ra cua module synchronizer (_w)
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync_w;
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync_w;

    // =========================================================================
    // MIEN WRITE (wr_clk)
    // =========================================================================
    
    // Tinh toan dia chi Binary tiep theo
    assign wr_ptr_bin_next_w = wr_ptr_bin_r + (we_i & ~full_o);

    // Goi module bin_to_gray de tao ma Gray tiep theo
    // (Luu y: Module bin_to_gray hien tai van dung ten port cu la bin, gray)
    bin_to_gray #(.WIDTH(ADDR_WIDTH + 1)) u_b2g_wr (
        .bin_i  (wr_ptr_bin_next_w),
        .gray_o (wr_ptr_gray_next_w)
    );

    always @(posedge wr_clk_i) begin
        if (wr_rst_i) begin
            wr_ptr_bin_r  <= 0;
            wr_ptr_gray_r <= 0;
            full_o        <= 0;
        end else begin
            // Ghi du lieu vao RAM
            if (we_i && !full_o) begin
                mem_r[wr_ptr_bin_r[ADDR_WIDTH-1:0]] <= din_i;
            end
            
            // Cap nhat con tro (Luc nay wr_ptr_gray_r se duoc chot vao D-FF, het glitch)
            wr_ptr_bin_r  <= wr_ptr_bin_next_w;
            wr_ptr_gray_r <= wr_ptr_gray_next_w;
            
            // Tinh toan co Full
            full_o <= (wr_ptr_gray_next_w == {~rd_ptr_gray_sync_w[ADDR_WIDTH:ADDR_WIDTH-1], 
                                               rd_ptr_gray_sync_w[ADDR_WIDTH-2:0]});
        end
    end

    // Dong bo con tro doc (rd_ptr_gray_r) vao mien ghi (wr_clk_i)
    // (Luu y: Module synchronizer hien tai van dung ten port cu la clk, rst, d_in, d_out)
    synchronizer #(.WIDTH(ADDR_WIDTH + 1)) u_sync_rd2wr (
        .clk_i   (wr_clk_i),
        .rst_i   (wr_rst_i),
        .d_in_i  (rd_ptr_gray_r),      // Dua REG vao chong Metastability
        .d_out_o (rd_ptr_gray_sync_w)
    );


    // =========================================================================
    // MIEN READ (rd_clk)
    // =========================================================================
    
    // Tinh toan dia chi Binary tiep theo
    assign rd_ptr_bin_next_w = rd_ptr_bin_r + (re_i & ~empty_o);

    // Goi module bin_to_gray de tao ma Gray tiep theo
    bin_to_gray #(.WIDTH(ADDR_WIDTH + 1)) u_b2g_rd (
        .bin_i  (rd_ptr_bin_next_w),
        .gray_o (rd_ptr_gray_next_w)
    );

    always @(posedge rd_clk_i) begin
        if (rd_rst_i) begin
            rd_ptr_bin_r  <= 0;
            rd_ptr_gray_r <= 0;
            dout_o        <= 0;
            empty_o       <= 1'b1;
        end else begin
            // Doc du lieu tu RAM
            if (re_i && !empty_o) begin
                dout_o <= mem_r[rd_ptr_bin_r[ADDR_WIDTH-1:0]];
            end
            
            // Cap nhat con tro
            rd_ptr_bin_r  <= rd_ptr_bin_next_w;
            rd_ptr_gray_r <= rd_ptr_gray_next_w;
            
            // Tinh toan co Empty
            empty_o <= (rd_ptr_gray_next_w == wr_ptr_gray_sync_w);
        end
    end

    // Dong bo con tro ghi (wr_ptr_gray_r) vao mien doc (rd_clk_i)
    synchronizer #(.WIDTH(ADDR_WIDTH + 1)) u_sync_wr2rd (
        .clk_i   (rd_clk_i),
        .rst_i   (rd_rst_i),
        .d_in_i  (wr_ptr_gray_r),      
        .d_out_o (wr_ptr_gray_sync_w)
    );

endmodule
