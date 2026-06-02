module VGA_controller (
    // Host Side
    input  [9:0]  iRed,
    input  [9:0]  iGreen,
    input  [9:0]  iBlue,
    output [10:0] oCurrent_X,
    output [10:0] oCurrent_Y,
    output [21:0] oAddress,
    output        oRequest,
    // VGA Side
    output [9:0]  oVGA_R,
    output [9:0]  oVGA_G,
    output [9:0]  oVGA_B,
    output reg    oVGA_HS,
    output reg    oVGA_VS,
    output        oVGA_SYNC,
    output reg    oVGA_BLANK,
    output        oVGA_CLOCK,
    // Control Signal
    input         iCLK,   // Phải cấp đúng 25.175 MHz hoặc 25 MHz từ PLL
    input         iRST_N
);

    // Horizontal Timing Parameters (640x480 @ 60Hz) - Định nghĩa rõ 11-bit
    parameter [10:0] H_FRONT = 11'd16;
    parameter [10:0] H_SYNC  = 11'd96;
    parameter [10:0] H_BACK  = 11'd48;
    parameter [10:0] H_ACT   = 11'd640;
    parameter [10:0] H_BLANK = H_FRONT + H_SYNC + H_BACK;
    parameter [10:0] H_TOTAL = H_FRONT + H_SYNC + H_BACK + H_ACT; // 800

    // Vertical Timing Parameters (Chuẩn hóa VESA) - Định nghĩa rõ 11-bit
    parameter [10:0] V_FRONT = 11'd10;
    parameter [10:0] V_SYNC  = 11'd2;
    parameter [10:0] V_BACK  = 11'd33;
    parameter [10:0] V_ACT   = 11'd480;
    parameter [10:0] V_BLANK = V_FRONT + V_SYNC + V_BACK;
    parameter [10:0] V_TOTAL = V_FRONT + V_SYNC + V_BACK + V_ACT; // 525

    // Internal Registers
    reg [10:0] H_Cont;
    reg [10:0] V_Cont;
    reg [10:0] VGA_X;
    reg [10:0] VGA_Y;
    reg [9:0]  VGA_R, VGA_G, VGA_B;

    // [SỬA ĐỔI]: Các thanh ghi tạo độ trễ (Pipeline Registers) - Mở rộng thành Shift Register 4-bit
    reg c_HS, c_VS, c_BLANK;
    reg [3:0] vga_hs_pipe;
    reg [3:0] vga_vs_pipe;
    reg [3:0] vga_blank_pipe;
	 reg [10:0] pipe_x1, pipe_x2, pipe_x3;
    reg [10:0] pipe_y1, pipe_y2, pipe_y3;

    // Giao tiếp cố định cho chip DAC ADV7123 trên kit Terasic
    assign oVGA_SYNC  = 1'b0;
    assign oVGA_CLOCK = ~iCLK;

    // Xuất dữ liệu trực tiếp từ các thanh ghi đã được đồng bộ hóa pha
    assign oVGA_R = VGA_R;
    assign oVGA_G = VGA_G;
    assign oVGA_B = VGA_B;

    // Đưa tọa độ và địa chỉ ra ngoài cho DMA/Memory Controller đọc trước
    // Lệnh này không bị trễ nên FIFO vẫn nạp dữ liệu từ sớm
    assign oCurrent_X = (H_Cont >= H_BLANK) ? (H_Cont - H_BLANK) : 11'd0;
    assign oCurrent_Y = (V_Cont >= V_BLANK) ? (V_Cont - V_BLANK) : 11'd0;
    
    // Ép kiểu vế phải lên đúng 22-bit để khớp hoàn hảo với bus oAddress
    assign oAddress   = ({11'd0, oCurrent_Y} * 22'd640) + {11'd0, oCurrent_X};
    assign oRequest   = ((H_Cont >= H_BLANK) && (V_Cont >= V_BLANK));

    // Bộ đếm quét Ngang (Horizontal) và Dọc (Vertical) đồng bộ chung 1 Clock
    always @(posedge iCLK or negedge iRST_N) begin
         if (!iRST_N) begin
              H_Cont <= 11'd0;
              V_Cont <= 11'd0;
         end else begin
              // Quét Ngang
              if (H_Cont < H_TOTAL - 1'b1) begin
                    H_Cont <= H_Cont + 1'b1;
              end else begin
                    H_Cont <= 11'd0;
                    // Quét Dọc (Chỉ tăng khi kết thúc 1 dòng ngang)
                    if (V_Cont < V_TOTAL - 1'b1) begin
                         V_Cont <= V_Cont + 1'b1;
                    end else begin
                         V_Cont <= 11'd0;
                    end
              end
         end
    end

    // Khối tạo tín hiệu điều khiển gốc (Tầng logic 0)
    always @(*) begin
         c_HS    = ~((H_Cont >= H_FRONT) && (H_Cont < H_FRONT + H_SYNC));
         c_VS    = ~((V_Cont >= V_FRONT) && (V_Cont < V_FRONT + V_SYNC));
         c_BLANK =  ((H_Cont >= H_BLANK) && (V_Cont >= V_BLANK));
    end

    // [SỬA ĐỔI HOÀN HẢO]: Bộ đếm tọa độ Pipeline an toàn
    always @(posedge iCLK or negedge iRST_N) begin
         if (!iRST_N) begin
              VGA_X          <= 11'd0;
              VGA_Y          <= 11'd0;
              vga_hs_pipe    <= 4'b1111;
              vga_vs_pipe    <= 4'b1111;
              vga_blank_pipe <= 4'b0000;
              
              // Reset mảng trễ tọa độ
              pipe_x1 <= 11'd0; pipe_x2 <= 11'd0; pipe_x3 <= 11'd0;
              pipe_y1 <= 11'd0; pipe_y2 <= 11'd0; pipe_y3 <= 11'd0;
         end else begin
              // 1. Luôn dịch mạch pipe tín hiệu điều khiển độc lập
              vga_hs_pipe    <= {vga_hs_pipe[2:0], c_HS};
              vga_vs_pipe    <= {vga_vs_pipe[2:0], c_VS};
              vga_blank_pipe <= {vga_blank_pipe[2:0], c_BLANK};
              
              // >>> THÊM VÀO: Đẩy VGA_X và VGA_Y qua 3 tầng trễ <<<
              pipe_x1 <= VGA_X;
              pipe_x2 <= pipe_x1;
              pipe_x3 <= pipe_x2;
              
              pipe_y1 <= VGA_Y;
              pipe_y2 <= pipe_y1;
              pipe_y3 <= pipe_y2;

              // 2. Logic đếm tọa độ gốc (Giữ nguyên đoạn này của bạn)
              if (c_BLANK) begin
                   if (VGA_X < H_ACT - 1'b1) begin
                        VGA_X <= VGA_X + 1'b1; 
                   end else begin
                        VGA_X <= 11'd0;        
                        if (VGA_Y < V_ACT - 1'b1) begin
                             VGA_Y <= VGA_Y + 1'b1; 
                        end else begin
                             VGA_Y <= 11'd0;        
                        end
                   end
              end else begin
                   VGA_X <= 11'd0;
                   if (H_Cont == 11'd0 && V_Cont == 11'd0) begin
                        VGA_Y <= 11'd0;
                   end
              end
         end
    end

    // [SỬA ĐỔI]: Khối chọn màu xuất xưởng (Khớp thời gian hoàn hảo với luồng xử lý ảnh)
    always @(posedge iCLK or negedge iRST_N) begin
         if (!iRST_N) begin
              VGA_R      <= 10'd0;
              VGA_G      <= 10'd0;
              VGA_B      <= 10'd0;
              oVGA_HS    <= 1'b1;
              oVGA_VS    <= 1'b1;
              oVGA_BLANK <= 1'b0;
         end else begin
              // Đồng bộ các tín hiệu điều khiển lấy từ tầng trễ thứ 4 (vị trí [3] của mảng)
              oVGA_HS    <= vga_hs_pipe[3];
              oVGA_VS    <= vga_vs_pipe[3];
              oVGA_BLANK <= vga_blank_pipe[3];

              // Nếu nằm ngoài vùng hiển thị chủ động thì tắt màu hoàn toàn (Màu đen)
              // Sử dụng tín hiệu blank đã trễ để đánh giá
              if (!vga_blank_pipe[3]) begin
                    VGA_R <= 10'd0;
                    VGA_G <= 10'd0;
                    VGA_B <= 10'd0;
              end else begin
                    // Test Pattern
                    if ((pipe_x3 == 11'd320) || (pipe_y3 == 11'd240) || (pipe_x3 == 11'd180) || (pipe_y3 == 11'd120)) begin
                         VGA_R <= 10'h3FF; // Đỏ max
                         VGA_G <= 10'h000;
                         VGA_B <= 10'h000;
                    end else begin
                         // Nếu không trúng vạch test thì xuất ảnh từ bộ xử lý ảnh/RAM
                         VGA_R <= iRed;
                         VGA_G <= iGreen;
                         VGA_B <= iBlue;
                    end
              end
         end
    end

endmodule