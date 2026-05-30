module Grayscale_to_RGB10 (
    input  wire        iCLK,
    input  wire        iRST_N,
    input  wire        i_valid,
    input  wire [7:0]  iY,         // Chỉ nhận đầu vào là độ sáng Y (8-bit)
    
    output reg         o_valid,
    output reg  [9:0]  oRed,       // Ngõ ra 10-bit cho bộ DAC VGA
    output reg  [9:0]  oGreen,
    output reg  [9:0]  oBlue
);

   // Thêm stage trễ nội bộ để đồng bộ với YUV444_to_RGB10 (2 stage)
	reg [9:0] oRed_d1, oGreen_d1, oBlue_d1;
	reg       o_valid_d1;

	always @(posedge iCLK or negedge iRST_N) begin
		 if (!iRST_N) begin
			  oRed_d1   <= 10'd0;
			  oGreen_d1 <= 10'd0;
			  oBlue_d1  <= 10'd0;
			  o_valid_d1 <= 1'b0;
		 end else begin
			  oRed_d1    <= {iY, 2'b00};
			  oGreen_d1  <= {iY, 2'b00};
			  oBlue_d1   <= {iY, 2'b00};
			  o_valid_d1 <= i_valid;
		 end
	end

	// Stage 2: thêm 1 cycle trễ nữa
	always @(posedge iCLK or negedge iRST_N) begin
		 if (!iRST_N) begin
			  o_valid <= 1'b0;
			  oRed    <= 10'd0;
			  oGreen  <= 10'd0;
			  oBlue   <= 10'd0;
		 end else begin
			  o_valid <= o_valid_d1;
			  oRed    <= oRed_d1;
			  oGreen  <= oGreen_d1;
			  oBlue   <= oBlue_d1;
		 end
	end

endmodule