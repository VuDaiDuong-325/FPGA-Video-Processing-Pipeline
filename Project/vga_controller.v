// vga_controller.v
module vga_controller (
    input  wire        vga_clk,     // Xung nhịp VGA 25MHz
    input  wire        rst,         // Reset hệ thống (Active-High)
    output reg         hsync,
    output reg         vsync,
    output wire        blank_n,     // Mức 1 khi nằm trong vùng hiển thị active, mức 0 khi ở vùng rìa
    output wire        sync_n,      // Cố định mức 0 (yêu cầu của chip DAC trên các board DE-series)
    output wire [9:0]  pixel_x,     // Tọa độ pixel trục X (0 -> 639)
    output wire [9:0]  pixel_y      // Tọa độ pixel trục Y (0 -> 478)
);
    // Thông số Timing chuẩn VGA 640x480 @ 60Hz
    localparam H_ACTIVE    = 640;
    localparam H_FRONT     = 16;
    localparam H_SYNC      = 96;
    localparam H_BACK      = 48;
    localparam H_TOTAL     = 800;

    localparam V_ACTIVE    = 480;
    localparam V_FRONT     = 10;
    localparam V_SYNC      = 2;
    localparam V_BACK      = 33;
    localparam V_TOTAL     = 525;

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // Bộ đếm quét ngang
    always @(posedge vga_clk or posedge rst) begin
        if (rst)
            h_cnt <= 10'd0;
        else if (h_cnt == H_TOTAL - 1)
            h_cnt <= 10'd0;
        else
            h_cnt <= h_cnt + 10'd1;
    end

    // Bộ đếm quét dọc
    always @(posedge vga_clk or posedge rst) begin
        if (rst)
            v_cnt <= 10'd0;
        else if (h_cnt == H_TOTAL - 1) begin
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 10'd0;
            else
                v_cnt <= v_cnt + 10'd1;
        end
    end

    // Tạo tín hiệu HSYNC và VSYNC (Active-Low)
    always @(posedge vga_clk or posedge rst) begin
        if (rst) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_cnt >= (H_ACTIVE + H_FRONT)) && (h_cnt < (H_ACTIVE + H_FRONT + H_SYNC)));
            vsync <= ~((v_cnt >= (V_ACTIVE + V_FRONT)) && (v_cnt < (V_ACTIVE + V_FRONT + V_SYNC)));
        end
    end

    // Xác định vùng hiển thị tích cực
    assign blank_n = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    assign sync_n  = 1'b0;

    assign pixel_x = (h_cnt < H_ACTIVE) ? h_cnt : 10'd0;
    assign pixel_y = (v_cnt < V_ACTIVE) ? v_cnt : 10'd0;

endmodule