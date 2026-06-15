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

    wire c_HS    = ~((H_Cont >= H_FRONT) && (H_Cont < H_FRONT + H_SYNC));
    wire c_VS    = ~((V_Cont >= V_FRONT) && (V_Cont < V_FRONT + V_SYNC));
    wire c_BLANK =  (H_Cont >= H_BLANK)  && (V_Cont >= V_BLANK);

    reg [4:0] vga_hs_pipe, vga_vs_pipe, vga_blank_pipe;

    // ADV7123: SYNC=0 (dùng HS/VS riêng), CLK=~iCLK
    assign oVGA_SYNC  = 1'b0;
    assign oVGA_CLOCK = ~iCLK;

    assign oVGA_R     = VGA_R[9:2];
    assign oVGA_G     = VGA_G[9:2];
    assign oVGA_B     = VGA_B[9:2];

    assign oCurrent_X = (H_Cont >= H_BLANK) ? (H_Cont - H_BLANK) : 11'd0;
    assign oCurrent_Y = (V_Cont >= V_BLANK)  ? (V_Cont - V_BLANK)  : 11'd0;
    assign oAddress   = ({11'd0, oCurrent_Y} * 22'd640) + {11'd0, oCurrent_X};

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

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            vga_hs_pipe    <= 5'b11111;
            vga_vs_pipe    <= 5'b11111;
            vga_blank_pipe <= 5'b00000;
        end else begin
            vga_hs_pipe    <= {vga_hs_pipe[3:0],    c_HS};
            vga_vs_pipe    <= {vga_vs_pipe[3:0],    c_VS};
            vga_blank_pipe <= {vga_blank_pipe[3:0], c_BLANK};
        end
    end

    // Output register - Stage 5 (cuối) của data pipeline
    // vga_blank_pipe[4] tại posedge này = c_BLANK từ 5 cycles trước = lúc rdreq bắt đầu
    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            VGA_R      <= 10'd0;
            VGA_G      <= 10'd0;
            VGA_B      <= 10'd0;
            oVGA_HS    <= 1'b1;
            oVGA_VS    <= 1'b1;
            oVGA_BLANK <= 1'b0;
        end else begin
            oVGA_HS    <= vga_hs_pipe[4];
            oVGA_VS    <= vga_vs_pipe[4];
            oVGA_BLANK <= vga_blank_pipe[4];

            if (vga_blank_pipe[4]) begin
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