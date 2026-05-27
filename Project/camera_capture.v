module camera_capture (
		input wire 			pclk_i,
		input wire 			rst_n_i,
		input wire 			vsync_i,				// vertical sync = 1 -> quet khung hinh moi=
		input wire 			href_i,				// hoprizontal reference = 1 -> D la 1 hang diem anh
		input wire [7:0] 	din_i,
		output reg [15:0] pixel_data_o,
		output reg			pixel_valid_o
);

	reg [7:0] 	temp_byte_r;					// Giu 8 bit dau (bit cao)
	reg 			byte_state_r;					// Bao nhip (nhan 2 nhip din)
	
	always @(posedge pclk_i or negedge rst_n_i) begin
		if (!rst_n_i) begin
			temp_byte_r 		<= 8'd0;
			byte_state_r 		<= 1'd0;
			pixel_data_o 		<= 16'd0;
			pixel_valid_o 		<= 1'd0;
		end
		else if (vsync_i) begin
			temp_byte_r 		<= 8'd0;
			byte_state_r 		<= 1'd0;
			pixel_data_o 		<= 16'd0;
			pixel_valid_o 		<= 1'd0;
		end 
		else if (href_i) begin
			if (!byte_state_r) begin
				temp_byte_r 	<= din_i;
				byte_state_r 	<= 1'd1;
				pixel_valid_o 	<= 1'd0;
			end 
			else begin
				pixel_data_o 	<= {temp_byte_r, din_i};
				pixel_valid_o 	<= 1'd1;
				byte_state_r 	<= 1'd0;
			end
		end
		else 
			pixel_valid_o 		<= 1'd0;
			byte_state_r 		<= 1'd0;
	end
endmodule
