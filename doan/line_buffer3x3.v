module line_buffer3x3 #(
    parameter WIDTH = 10,
    parameter IMG_W = 640,
    parameter IMG_H = 480
) (
    input  wire                 iCLK,
    input  wire                 iRST_N,
    input  wire                 i_valid,
    input  wire [10:0]          i_x,      // oCurrent_X (0..639)
    input  wire [10:0]          i_y,      // oCurrent_Y (0..479)
    input  wire [WIDTH-1:0]     iData,

    output wire [WIDTH-1:0]     p00, p01, p02,
    output wire [WIDTH-1:0]     p10, p11, p12,
    output wire [WIDTH-1:0]     p20, p21, p22,
    output wire                 o_valid,     
    output wire                 o_edge_pixel // 1 = window chạm biên ảnh
);

    localparam AW = 10; // log2(640)=10 đủ cho địa chỉ line buffer 640 word

    // ---------------------------------------------------------------
    // Line delay RAM 0: trễ 1 dòng (640 pixel)
    // ---------------------------------------------------------------
    reg [WIDTH-1:0] lb0_mem [0:IMG_W-1];
    reg [WIDTH-1:0] lb0_q;

    // ---------------------------------------------------------------
    // Line delay RAM 1: trễ 1 dòng nữa (tổng 2 dòng)
    // ---------------------------------------------------------------
    reg [WIDTH-1:0] lb1_mem [0:IMG_W-1];
    reg [WIDTH-1:0] lb1_q;

    wire [AW-1:0] addr_x = i_x[AW-1:0];

    // Đọc trước khi ghi (read-old-data), đúng hành vi M10K mặc định
    always @(posedge iCLK) begin
        if (i_valid) begin
            lb0_q <= lb0_mem[addr_x];
            lb0_mem[addr_x] <= iData;

            lb1_q <= lb1_mem[addr_x];
            lb1_mem[addr_x] <= lb0_q;
        end
    end

    // d_row0 = iData (dòng y),  d_row1 = lb0_q (dòng y-1),  d_row2 = lb1_q (dòng y-2)
    wire [WIDTH-1:0] d_row0 = iData;
    wire [WIDTH-1:0] d_row1 = lb0_q;
    wire [WIDTH-1:0] d_row2 = lb1_q;

    // ---------------------------------------------------------------
    // Shift theo trục x: mỗi "dòng" cần 2 thanh ghi delay (x-1, x-2)
    // ---------------------------------------------------------------
    reg [WIDTH-1:0] row0_d1, row0_d2;
    reg [WIDTH-1:0] row1_d1, row1_d2;
    reg [WIDTH-1:0] row2_d1, row2_d2;

    reg [1:0]  valid_pipe;
    reg [10:0] x_pipe1, x_pipe2;
    reg [10:0] y_pipe1, y_pipe2;

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            row0_d1 <= 0; row0_d2 <= 0;
            row1_d1 <= 0; row1_d2 <= 0;
            row2_d1 <= 0; row2_d2 <= 0;
            valid_pipe <= 2'b00;
            x_pipe1 <= 11'd0; x_pipe2 <= 11'd0;
            y_pipe1 <= 11'd0; y_pipe2 <= 11'd0;
        end else begin
            valid_pipe <= {valid_pipe[0], i_valid};
            x_pipe1 <= i_x; x_pipe2 <= x_pipe1;
            y_pipe1 <= i_y; y_pipe2 <= y_pipe1;

            if (i_valid) begin
                row0_d2 <= row0_d1; row0_d1 <= d_row0;
                row1_d2 <= row1_d1; row1_d1 <= d_row1;
                row2_d2 <= row2_d1; row2_d1 <= d_row2;
            end
        end
    end

    // Window 3x3, center = (x_pipe2-1... thực chất center tương ứng x_pipe1, y-1)
    //   row2 = dòng cũ nhất (y-2), row0 = dòng mới nhất (y)
    assign p00 = row2_d2; assign p01 = row2_d1; assign p02 = d_row2;
    assign p10 = row1_d2; assign p11 = row1_d1; assign p12 = d_row1;
    assign p20 = row0_d2; assign p21 = row0_d1; assign p22 = d_row0;

    assign o_valid = valid_pipe[1];

    // Window không hợp lệ khi pixel trung tâm (x_pipe2, y_pipe2) nằm trong
    // 2 dòng/cột đầu của ảnh (chưa có đủ history 2 dòng/2 cột trước đó)
    assign o_edge_pixel = (x_pipe2 < 11'd2) || (y_pipe2 < 11'd2);

endmodule