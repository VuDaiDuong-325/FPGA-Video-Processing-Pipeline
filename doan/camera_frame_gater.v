module camera_frame_gater #(
    parameter FRAME_DELAY = 8'd150 // 150 frames ~ 5 giây với camera 30 FPS
)(
    input wire        iCAM_PCLK,    // Clock từ chân Camera
    input wire        iRST_N,
    
    // Tín hiệu gốc từ Camera OV7670
    input wire        iCAM_VSYNC,
    input wire        iCAM_HREF,
    input wire [7:0]  iCAM_DATA,
    
    // Tín hiệu sau khi lọc (Nối vào mạch ghi FIFO/SDRAM của bạn)
    output reg        oGATE_VSYNC,
    output reg        oGATE_HREF,
    output reg [7:0]  oGATE_DATA
);

    reg [7:0] frame_counter;
    reg       r_vsync_d1;
    wire      vsync_rising_edge;
    reg       gate_open;

    // Phát hiện cạnh lên của VSYNC (Bắt đầu một Sync Pulse mới)
    always @(posedge iCAM_PCLK or negedge iRST_N) begin
        if (!iRST_N)
            r_vsync_d1 <= 1'b0;
        else
            r_vsync_d1 <= iCAM_VSYNC;
    end
    assign vsync_rising_edge = (iCAM_VSYNC && !r_vsync_d1);

    // Bộ đếm khung hình và quản lý trạng thái Đóng/Mở cửa (Gate)
    always @(posedge iCAM_PCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            frame_counter <= 8'd0;
            gate_open     <= 1'b0;
        end 
        else begin
            if (vsync_rising_edge) begin
                if (frame_counter >= FRAME_DELAY - 1) begin
                    frame_counter <= 8'd0;
                    gate_open     <= 1'b1;  // Mở cửa cho khung hình này đi qua
                end else begin
                    frame_counter <= frame_counter + 1'b1;
                    gate_open     <= 1'b0;  // Đóng cửa chặn các khung hình trung gian
                end
            end
        end
    end

    // Logic điều khiển xuất dữ liệu
    always @(*) begin
        if (gate_open) begin
            // Khi mở cửa: Truyền thẳng dữ liệu Camera ra ngoài
            oGATE_VSYNC = iCAM_VSYNC;
            oGATE_HREF  = iCAM_HREF;
            oGATE_DATA  = iCAM_DATA;
        end else begin
            // Khi đóng cửa: Giữ các đường sọc đồng bộ ở mức IDLE (Màn hình giữ khung hình cũ)
            oGATE_VSYNC = 1'b0;
            oGATE_HREF  = 1'b0;
            oGATE_DATA  = 8'd0;
        end
    end

endmodule