// =========================================================================
// FILE: VGA_controller.v  [FIX v2 - CHÍNH XÁC]
//
// PIPELINE PHÂN TÍCH:
//   T0 (H=H_BLANK): rdreq=1, fifo_q=pixel[N], Decoder nhận data
//   T1 posedge:     Decoder latch → oRed=r(N)           [Stage 1]
//   T2 posedge:     Image_Processor MUX latch → oRed=r(N) [Stage 2]
//   T3 posedge:     VGA_R latch iRed=r(N)               [Stage 3]
//                   vga_blank_pipe[2](old at T3) = c_BLANK(T0) = 1 ✓
//
//   Tổng: 3 register stages → dùng pipe[2] (3 tầng), KHÔNG phải pipe[3]
//   oRequest = H_Cont >= H_BLANK (không sớm hơn)
//
// [FIX-1] pipe[2:0] thay vì pipe[3:0] → đồng bộ đúng với data pipeline 3 stages
// [FIX-2] oRequest giữ nguyên = H_Cont >= H_BLANK (không dịch sớm)
// [FIX-3] Xóa VGA_X/VGA_Y nội bộ (không cần, dùng oCurrent_X/Y)
// =========================================================================

module VGA_controller (
    input  [9:0]  iRed,
    input  [9:0]  iGreen,
    input  [9:0]  iBlue,
    output [10:0] oCurrent_X,
    output [10:0] oCurrent_Y,
    output [21:0] oAddress,
    output        oRequest,
    output [7:0]  oVGA_R,
    output [7:0]  oVGA_G,
    output [7:0]  oVGA_B,
    output reg    oVGA_HS,
    output reg    oVGA_VS,
    output        oVGA_SYNC,
    output reg    oVGA_BLANK,
    output        oVGA_CLOCK,
    input         iCLK,
    input         iRST_N
);

    // VGA 640x480 @ 60Hz (pixel clock 25.175 MHz)
    parameter [10:0] H_FRONT = 11'd16;
    parameter [10:0] H_SYNC  = 11'd96;
    parameter [10:0] H_BACK  = 11'd48;
    parameter [10:0] H_ACT   = 11'd640;
    parameter [10:0] H_BLANK = H_FRONT + H_SYNC + H_BACK;    // 160
    parameter [10:0] H_TOTAL = H_BLANK + H_ACT;               // 800

    parameter [10:0] V_FRONT = 11'd10;
    parameter [10:0] V_SYNC  = 11'd2;
    parameter [10:0] V_BACK  = 11'd33;
    parameter [10:0] V_ACT   = 11'd480;
    parameter [10:0] V_BLANK = V_FRONT + V_SYNC + V_BACK;    // 45
    parameter [10:0] V_TOTAL = V_BLANK + V_ACT;               // 525

    reg [10:0] H_Cont, V_Cont;
    reg [9:0]  VGA_R, VGA_G, VGA_B;

    // Tín hiệu điều khiển combinational
    wire c_HS    = ~((H_Cont >= H_FRONT) && (H_Cont < H_FRONT + H_SYNC));
    wire c_VS    = ~((V_Cont >= V_FRONT) && (V_Cont < V_FRONT + V_SYNC));
    wire c_BLANK =  (H_Cont >= H_BLANK)  && (V_Cont >= V_BLANK);

    // [FIX-1] 3 tầng pipeline (pipe[2:0]), khớp với 3 register stages của data path
    reg [2:0] vga_hs_pipe, vga_vs_pipe, vga_blank_pipe;

    // ADV7123: SYNC=0 (dùng HS/VS riêng), CLK=~iCLK
    assign oVGA_SYNC  = 1'b0;
    assign oVGA_CLOCK = ~iCLK;
    // [FIX-5] DE1-SoC ADV7123 chỉ có 8 chân thật/kênh (VGA_R/G/B[7:0]).
    //         Lấy 8 bit MSB [9:2] của giá trị 10-bit nội bộ để giữ đúng
    //         độ sáng (tương đương >>2), KHÔNG lấy [7:0] (gây sai mid-tone).
    assign oVGA_R     = VGA_R[9:2];
    assign oVGA_G     = VGA_G[9:2];
    assign oVGA_B     = VGA_B[9:2];

    // Tọa độ pixel hiện tại (combinational, không trễ)
    assign oCurrent_X = (H_Cont >= H_BLANK) ? (H_Cont - H_BLANK) : 11'd0;
    assign oCurrent_Y = (V_Cont >= V_BLANK)  ? (V_Cont - V_BLANK)  : 11'd0;
    assign oAddress   = ({11'd0, oCurrent_Y} * 22'd640) + {11'd0, oCurrent_X};

    // [FIX-2] oRequest = H_Cont >= H_BLANK (KHÔNG sớm)
    // Pixel[0] đọc tại H=H_BLANK → qua 3 stages → latch vào VGA_R tại H+3
    // Đồng thời blank_pipe[2](old at H+3) = c_BLANK(H_BLANK) = 1 ✓
    assign oRequest = (H_Cont >= H_BLANK) && (V_Cont >= V_BLANK);

    // Bộ đếm quét H/V
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            H_Cont <= 11'd0;
            V_Cont <= 11'd0;
        end else begin
            if (H_Cont < H_TOTAL - 1'b1)
                H_Cont <= H_Cont + 1'b1;
            else begin
                H_Cont <= 11'd0;
                V_Cont <= (V_Cont < V_TOTAL - 1'b1) ? V_Cont + 1'b1 : 11'd0;
            end
        end
    end

    // [FIX-1] Pipeline 3 tầng cho HS/VS/BLANK
    // Sau 3 posedge: pipe[2] chứa c_BLANK từ 3 cycle trước
    // Data pipeline cũng có 3 stages → đồng bộ hoàn hảo
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            vga_hs_pipe    <= 3'b111;
            vga_vs_pipe    <= 3'b111;
            vga_blank_pipe <= 3'b000;
        end else begin
            vga_hs_pipe    <= {vga_hs_pipe[1:0],    c_HS};
            vga_vs_pipe    <= {vga_vs_pipe[1:0],    c_VS};
            vga_blank_pipe <= {vga_blank_pipe[1:0], c_BLANK};
        end
    end

    // Output register - Stage 3 của data pipeline
    // vga_blank_pipe[2] tại posedge này = c_BLANK từ 3 cycles trước = lúc rdreq bắt đầu
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            VGA_R      <= 10'd0;
            VGA_G      <= 10'd0;
            VGA_B      <= 10'd0;
            oVGA_HS    <= 1'b1;
            oVGA_VS    <= 1'b1;
            oVGA_BLANK <= 1'b0;
        end else begin
            oVGA_HS    <= vga_hs_pipe[2];
            oVGA_VS    <= vga_vs_pipe[2];
            oVGA_BLANK <= vga_blank_pipe[2];

            if (vga_blank_pipe[2]) begin
                VGA_R <= iRed;
                VGA_G <= iGreen;
                VGA_B <= iBlue;
            end else begin
                VGA_R <= 10'd0;
                VGA_G <= 10'd0;
                VGA_B <= 10'd0;
            end
        end
    end

endmodule