`timescale 1ns / 1ps

module tb();

    // Khai báo tín hiệu Testbench
    reg        clk_25m;
    reg        rst_n;
    reg [9:0]  iRed;
    reg [9:0]  iGreen;
    reg [9:0]  iBlue;

    // Tín hiệu ngõ ra từ module
    wire [10:0] oCurrent_X;
    wire [10:0] oCurrent_Y;
    wire        oRequest;
    
    wire [9:0]  oVGA_R;
    wire [9:0]  oVGA_G;
    wire [9:0]  oVGA_B;
    wire        oVGA_HS;
    wire        oVGA_VS;
    wire        oVGA_SYNC;
    wire        oVGA_BLANK;
    wire        oVGA_CLOCK;

    // 1. Tạo xung nhịp 25MHz (chu kỳ 40ns)
    initial begin
        clk_25m = 0;
        forever #20 clk_25m = ~clk_25m;
    end

    // 2. Kịch bản test
    initial begin
        // Khởi tạo trạng thái ban đầu
        rst_n = 0;
        iRed   = 10'h3FF; // Gán cứng màu Đỏ (Max = 1023)
        iGreen = 10'h000;
        iBlue  = 10'h000;

        // Giữ Reset trong 100ns
        #100;
        rst_n = 1;

        // Chờ khoảng 17 ms (Mô phỏng quét xong 1 frame 60Hz)
        #17000000; 
        
        $display("Mo phong VGA_Controller hoan tat 1 Frame!");
        $stop;
    end

    // 3. Khởi tạo module cần test
    VGA_controller u_vga_test (
        .iCLK       (clk_25m),
        .iRST_N     (rst_n),
        .iRed       (iRed),
        .iGreen     (iGreen),
        .iBlue      (iBlue),
        
        .oCurrent_X (oCurrent_X),
        .oCurrent_Y (oCurrent_Y),
        .oAddress   (),         // Bỏ trống nếu không dùng
        .oRequest   (oRequest),
        
        .oVGA_R     (oVGA_R),
        .oVGA_G     (oVGA_G),
        .oVGA_B     (oVGA_B),
        .oVGA_HS    (oVGA_HS),
        .oVGA_VS    (oVGA_VS),
        .oVGA_SYNC  (oVGA_SYNC),
        .oVGA_BLANK (oVGA_BLANK),
        .oVGA_CLOCK (oVGA_CLOCK)
    );

endmodule