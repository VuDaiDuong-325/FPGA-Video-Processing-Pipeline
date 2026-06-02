// =============================================================================
// TESTBENCH: tb_doan_top.v
// MUC DICH: Kiem tra toan bo luong du lieu tu Camera OV7670 -> SDRAM -> VGA
// CONG CU:  ModelSim (Verilog-2001 thuan tuy, khong dung SystemVerilog)
// PHUONG PHAP:
//   - Thay the cac module hardware (PLL, SDRAM, FIFO, Qsys) bang Stub/Model
//   - Kiem tra 5 test case doc lap
// =============================================================================
`timescale 1ns / 1ps

module tb;

	// =============================================================================
	// THAM SO CAU HINH TESTBENCH
	// =============================================================================
	parameter CLK50_PERIOD  = 20;   // 50 MHz  -> 20 ns
	parameter CLK25_PERIOD  = 40;   // 25 MHz  -> 40 ns
	parameter PCLK_PERIOD   = 41;   // ~24 MHz -> 41 ns

	parameter H_ACTIVE      = 640;
	parameter V_ACTIVE      = 480;
	parameter TOTAL_PIXELS  = H_ACTIVE * V_ACTIVE; // 307200

	// =============================================================================
	// KHAI BAO PORT KET NOI VOI DUT (Design Under Test)
	// =============================================================================
	reg         CLOCK_50;
	reg  [3:0]  KEY;
	reg  [9:0]  SW;

	// SDRAM (stub - ghi nhan tin hieu)
	wire [12:0] DRAM_ADDR;
	wire [1:0]  DRAM_BA;
	wire        DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N;
	wire        DRAM_LDQM, DRAM_RAS_N, DRAM_UDQM, DRAM_WE_N;
	wire [15:0] DRAM_DQ;

	// Camera
	reg         CAM_PCLK, CAM_VSYNC, CAM_HREF;
	reg  [7:0]  CAM_DATA;
	wire        CAM_XCLK, CAM_SCL;
	wire        CAM_SDA;

	// VGA output
	wire [9:0]  VGA_R, VGA_G, VGA_B;
	wire        VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
	wire [9:0]  LEDR;

	// =============================================================================
	// BIEN QUAN SAT VA BO DEM KIEM TRA
	// =============================================================================
	integer     pixel_write_count;
	integer     frame_count;
	integer     vga_req_count;
	integer     failed_tests;
	integer     passed_tests;

	reg         vsync_prev_mon;
	reg         vga_vs_prev_mon;
	integer     vga_frame_count;

	// =============================================================================
	// STUB THAY THE MODULE PHUC TAP (PLL, Qsys, SDRAM)
	// Giai thich: Cac module nay phu thuoc IP Altera, khong the simulate truc tiep.
	// Ta thay bang model hanh vi tuong duong de kiem tra logic top-level.
	// =============================================================================

	// --- STUB PLL ---
	// Tao truc tiep clock thay vi dung IP Altera PLL
	reg clk_50m_sys_tb;
	reg clk_24m_cam_tb;
	reg clk_50m_sdram_tb;
	reg clk_25m_vga_tb;

	initial clk_50m_sys_tb   = 0;
	initial clk_24m_cam_tb   = 0;
	initial clk_50m_sdram_tb = 0;
	initial clk_25m_vga_tb   = 0;

	always #(CLK50_PERIOD/2)  clk_50m_sys_tb   = ~clk_50m_sys_tb;
	always #(CLK50_PERIOD/2)  clk_50m_sdram_tb = ~clk_50m_sdram_tb;
	always #(PCLK_PERIOD/2)   clk_24m_cam_tb   = ~clk_24m_cam_tb;
	always #(CLK25_PERIOD/2)  clk_25m_vga_tb   = ~clk_25m_vga_tb;

	// --- MODEL SDRAM DON GIAN (Chap nhan write, tra ve read data sau 2 cycle) ---
	// Ghi nhan so luong lenh write SDRAM de kiem tra
	reg  [15:0] sdram_mem [0:524287]; // 512K words = 1MB model
	reg         w_dma_waitrequest_r;
	reg         r_dma_waitrequest_r;
	reg         r_dma_readdatavalid_r;
	reg  [15:0] r_dma_readdata_r;
	wire [24:0] w_dma_addr_dut;
	wire [15:0] w_dma_writedata_dut;
	wire        w_dma_write_dut;
	wire [24:0] r_dma_addr_dut;
	wire        r_dma_read_dut;
	integer     sdram_write_cnt;
	integer     sdram_read_cnt;

	// Bien de theo doi trang thai bus Avalon
	reg [1:0]   read_delay_cnt;

	always @(posedge clk_50m_sys_tb or negedge KEY[0]) begin
		 if (!KEY[0]) begin
			  w_dma_waitrequest_r  <= 1'b0;
			  r_dma_waitrequest_r  <= 1'b0;
			  r_dma_readdatavalid_r<= 1'b0;
			  r_dma_readdata_r     <= 16'd0;
			  sdram_write_cnt      <= 0;
			  sdram_read_cnt       <= 0;
			  read_delay_cnt       <= 2'd0;
		 end else begin
			  // Mo hinh ghi: chap nhan ngay, dem so lan ghi
			  if (w_dma_write_dut && !w_dma_waitrequest_r) begin
					if (w_dma_addr_dut < 524288)
						 sdram_mem[w_dma_addr_dut] <= w_dma_writedata_dut;
					sdram_write_cnt <= sdram_write_cnt + 1;
			  end

			  // Mo hinh doc: tra ve du lieu sau 2 cycle (CAS latency = 2)
			  r_dma_readdatavalid_r <= 1'b0;
			  if (r_dma_read_dut && !r_dma_waitrequest_r) begin
					read_delay_cnt <= 2'd2;
					sdram_read_cnt <= sdram_read_cnt + 1;
			  end
			  if (read_delay_cnt > 0) begin
					read_delay_cnt <= read_delay_cnt - 1;
					if (read_delay_cnt == 1) begin
						 r_dma_readdatavalid_r <= 1'b1;
						 // Tra ve du lieu tu mo hinh bo nho (gia tri co dinh neu chua ghi)
						 r_dma_readdata_r <= (r_dma_addr_dut < 524288) ?
													sdram_mem[r_dma_addr_dut] : 16'hABCD;
					end
			  end
		 end
	end

	// --- MODEL VIDEO DCFIFO (Hoat dong duoc voi 2 clock domain khac nhau) ---
	// Thay bang FIFO synchronous don gian cho muc dich simulation
	// CAM FIFO: PCLK write, clk_50m read
	reg  [15:0] cam_fifo_mem  [0:255];
	reg  [7:0]  cam_fifo_wrptr;
	reg  [7:0]  cam_fifo_rdptr;
	wire        cam_fifo_empty = (cam_fifo_wrptr == cam_fifo_rdptr);
	wire        cam_fifo_full  = (cam_fifo_wrptr[6:0] == cam_fifo_rdptr[6:0]) &&
											(cam_fifo_wrptr[7] != cam_fifo_rdptr[7]);
	wire [15:0] cam_fifo_q     = cam_fifo_mem[cam_fifo_rdptr[6:0]];

	wire        cam_write_en_dut;
	wire [15:0] cam_data_16bit_dut;
	wire        sdram_wrreq_dut;

	always @(posedge CAM_PCLK or negedge KEY[0]) begin
		 if (!KEY[0]) cam_fifo_wrptr <= 8'd0;
		 else if (cam_write_en_dut && !cam_fifo_full) begin
			  cam_fifo_mem[cam_fifo_wrptr[6:0]] <= cam_data_16bit_dut;
			  cam_fifo_wrptr <= cam_fifo_wrptr + 1;
		 end
	end

	always @(posedge clk_50m_sys_tb or negedge KEY[0]) begin
		 if (!KEY[0]) cam_fifo_rdptr <= 8'd0;
		 else if (sdram_wrreq_dut && !cam_fifo_empty)
			  cam_fifo_rdptr <= cam_fifo_rdptr + 1;
	end

	// VGA FIFO: clk_50m write, clk_25m read
	reg  [15:0] vga_fifo_mem  [0:2047];
	reg  [10:0] vga_fifo_wrptr;
	reg  [10:0] vga_fifo_rdptr;
	wire        vga_fifo_empty_tb = (vga_fifo_wrptr[9:0] == vga_fifo_rdptr[9:0]) &&
												 (vga_fifo_wrptr[10] == vga_fifo_rdptr[10]);
	wire        vga_fifo_full_tb  = (vga_fifo_wrptr[9:0] == vga_fifo_rdptr[9:0]) &&
												 (vga_fifo_wrptr[10] != vga_fifo_rdptr[10]);
	wire [15:0] vga_fifo_q_tb     = vga_fifo_mem[vga_fifo_rdptr[9:0]];
	wire [10:0] vga_fifo_wrusedw_tb = vga_fifo_wrptr - vga_fifo_rdptr;

	wire        vga_fifo_wrreq_dut;
	wire [15:0] vga_fifo_wrdata_dut;
	wire        vga_req_dut;
	wire        vga_fifo_rdreq_dut;

	always @(posedge clk_50m_sys_tb or negedge KEY[0]) begin
		 if (!KEY[0]) vga_fifo_wrptr <= 11'd0;
		 else if (vga_fifo_wrreq_dut && !vga_fifo_full_tb) begin
			  vga_fifo_mem[vga_fifo_wrptr[9:0]] <= vga_fifo_wrdata_dut;
			  vga_fifo_wrptr <= vga_fifo_wrptr + 1;
		 end
	end

	always @(posedge clk_25m_vga_tb or negedge KEY[0]) begin
		 if (!KEY[0]) vga_fifo_rdptr <= 11'd0;
		 else if (vga_fifo_rdreq_dut && !vga_fifo_empty_tb)
			  vga_fifo_rdptr <= vga_fifo_rdptr + 1;
	end

	// =============================================================================
	// KHOI TAO DUT VOI CAC PORT DA MAP VOI STUB/MODEL
	// =============================================================================
	// Ghi chu: Thay vi instantiate doan_top truc tiep (se keo theo toan bo IP Altera),
	// ta kiem tra tung sub-module va luong tin hieu thong qua wire monitoring

	// --- Kiem tra module ov7670_capture ---
	ov7670_capture u_capture_dut (
		 .pclk     (CAM_PCLK),
		 .reset    (KEY[0]),
		 .vsync    (CAM_VSYNC),
		 .href     (CAM_HREF),
		 .data_in  (CAM_DATA),
		 .data_out (cam_data_16bit_dut),
		 .write_en (cam_write_en_dut)
	);

	// --- Kiem tra module YUV422_to_444 ---
	reg  [15:0] yuv422_input_tb;
	reg         yuv422_valid_tb;
	reg  [9:0]  yuv422_ix_tb;
	wire [7:0]  yuv_oY_tb, yuv_oCb_tb, yuv_oCr_tb;

	YUV422_to_444 u_yuv422_dut (
		 .iYCbCr  (yuv422_input_tb),
		 .i_valid (yuv422_valid_tb),
		 .oY      (yuv_oY_tb),
		 .oCb     (yuv_oCb_tb),
		 .oCr     (yuv_oCr_tb),
		 .iX      (yuv422_ix_tb),
		 .iCLK    (clk_25m_vga_tb),
		 .iRST_N  (KEY[0])
	);

	// --- Kiem tra module sdram_double_buffer_controller ---
	reg         sdram_wrreq_stub;
	reg  [15:0] sdram_wrdata_stub;
	reg         cam_vsync_stub;
	wire [24:0] w_addr_dut_tb;
	wire [15:0] w_data_dut_tb;
	wire        w_write_dut_tb;
	reg         w_waitreq_stub;

	sdram_double_buffer_controller u_sdram_write_dut (
		 .clk             (clk_50m_sys_tb),
		 .rst_n           (KEY[0]),
		 .cam_vsync       (cam_vsync_stub),
		 .cam_pixel_valid (sdram_wrreq_stub),
		 .cam_pixel_data  (sdram_wrdata_stub),
		 .avm_address     (w_addr_dut_tb),
		 .avm_writedata   (w_data_dut_tb),
		 .avm_write       (w_write_dut_tb),
		 .avm_waitrequest (w_waitreq_stub)
	);

	// Gan cac tin hieu monitor
	assign w_dma_addr_dut     = w_addr_dut_tb;
	assign w_dma_writedata_dut= w_data_dut_tb;
	assign w_dma_write_dut    = w_write_dut_tb;

	// =============================================================================
	// CLOCK GENERATION
	// =============================================================================
	initial CLOCK_50 = 0;
	always #(CLK50_PERIOD/2) CLOCK_50 = ~CLOCK_50;

	initial CAM_PCLK = 0;
	always #(PCLK_PERIOD/2) CAM_PCLK = ~CAM_PCLK;

	// =============================================================================
	// TASK TIEN ICH
	// =============================================================================
	task do_reset;
		 begin
			  KEY[0] <= 1'b0;
			  repeat(10) @(posedge CLOCK_50);
			  KEY[0] <= 1'b1;
			  repeat(5) @(posedge CLOCK_50);
		 end
	endtask

	// Phat mot dong pixel camera (HREF active, n pixel = 2n byte YUYV)
	task send_camera_line;
		 input integer num_pixels;
		 input [7:0] base_y;
		 input [7:0] base_cb;
		 input [7:0] base_cr;
		 integer i;
		 begin
			  @(posedge CAM_PCLK); CAM_HREF <= 1'b1;
			  for (i = 0; i < num_pixels; i = i + 1) begin
					// Byte 1: Y (pixel chan)
					@(posedge CAM_PCLK); CAM_DATA <= base_y + i[7:0];
					// Byte 2: Cb
					@(posedge CAM_PCLK); CAM_DATA <= base_cb;
					// Byte 3: Y (pixel le)
					@(posedge CAM_PCLK); CAM_DATA <= base_y + i[7:0] + 8'd1;
					// Byte 4: Cr
					@(posedge CAM_PCLK); CAM_DATA <= base_cr;
			  end
			  @(posedge CAM_PCLK); CAM_HREF <= 1'b0;
			  CAM_DATA <= 8'd0;
			  // Horizontal blanking
			  repeat(144) @(posedge CAM_PCLK);
		 end
	endtask

	// Phat mot frame day du (VSYNC + 480 dong)
	task send_camera_frame;
		 input [7:0] base_y;
		 integer line;
		 begin
			  // VSYNC rising edge: ket thuc frame truoc (blanking period HIGH)
			  @(posedge CAM_PCLK); CAM_VSYNC <= 1'b1; CAM_HREF <= 1'b0;
			  repeat(3) @(posedge CAM_PCLK);
			  // VSYNC falling edge: bat dau frame moi (active LOW)
			  @(posedge CAM_PCLK); CAM_VSYNC <= 1'b0;
			  // Vertical blanking sau VSYNC
			  repeat(17) @(posedge CAM_PCLK);
			  // 480 dong active
			  for (line = 0; line < V_ACTIVE; line = line + 1) begin
					send_camera_line(H_ACTIVE/2, base_y + line[7:0], 8'h80, 8'h80);
			  end
			  // VSYNC ket thuc frame - len HIGH
			  @(posedge CAM_PCLK); CAM_VSYNC <= 1'b1;
			  repeat(3) @(posedge CAM_PCLK);
			  frame_count = frame_count + 1;
		 end
	endtask

	// Task kiem tra co dieu kien
	task check_condition;
		 input condition;
		 input [127:0] test_name;
		 begin
			  if (condition) begin
					$display("[PASS] %0s", test_name);
					passed_tests = passed_tests + 1;
			  end else begin
					$display("[FAIL] %0s", test_name);
					failed_tests = failed_tests + 1;
			  end
		 end
	endtask

	// =============================================================================
	// BO THEO DOI (MONITOR) - Tu dong dem tin hieu
	// =============================================================================

	// Dem so pixel ghi vao SDRAM (ov7670_capture phat write_en)
	always @(posedge CAM_PCLK) begin
		 if (cam_write_en_dut)
			  pixel_write_count <= pixel_write_count + 1;
	end

	// Dem VGA HS/VS frame
	always @(posedge clk_25m_vga_tb) begin
		 vsync_prev_mon <= VGA_VS;
		 if (VGA_VS && !vsync_prev_mon)
			  vga_frame_count <= vga_frame_count + 1;
	end

	// =============================================================================
	// KICH BAN KIEM THU CHINH
	// =============================================================================
	initial begin
		 // --- Khoi tao tat ca bien ---
		 KEY          = 4'hF;
		 SW           = 10'd0;
		 CAM_VSYNC    = 1'b0;
		 CAM_HREF     = 1'b0;
		 CAM_DATA     = 8'd0;
		 pixel_write_count = 0;
		 frame_count       = 0;
		 vga_req_count     = 0;
		 failed_tests      = 0;
		 passed_tests      = 0;
		 vga_frame_count   = 0;
		 vsync_prev_mon    = 0;
		 sdram_wrreq_stub  = 0;
		 sdram_wrdata_stub = 16'd0;
		 cam_vsync_stub    = 0;
		 w_waitreq_stub    = 0;
		 yuv422_input_tb   = 16'd0;
		 yuv422_valid_tb   = 0;
		 yuv422_ix_tb      = 10'd0;

		 $display("=================================================");
		 $display("  TESTBENCH: CAMERA OV7670 -> SDRAM -> VGA");
		 $display("  Target: DE1-SoC 5CSEMA5F31C6 RevH");
		 $display("=================================================");

		 // =========================================================================
		 // TEST 1: KIEM TRA RESET HE THONG
		 // Muc dich: Dam bao tat ca reg reset ve 0 sau khi KEY[0] = 0
		 // Ket qua du kien: write_en=0, byte_flag=0, avm_write=0
		 // =========================================================================
		 $display("\n--- TEST 1: System Reset ---");
		 do_reset;
		 repeat(5) @(posedge clk_50m_sys_tb);
		 check_condition(cam_write_en_dut === 1'b0,   "T1.1: cam_write_en = 0 sau reset");
		 check_condition(w_write_dut_tb   === 1'b0,   "T1.2: avm_write = 0 sau reset");
		 check_condition(w_addr_dut_tb    === 25'd0,  "T1.3: avm_address = 0 sau reset");

		 // =========================================================================
		 // TEST 2: KIEM TRA OV7670_CAPTURE - GHEP BYTE YUYV CHINH XAC
		 // Muc dich: Camera phat [Y0=0xA0, Cb=0x80, Y1=0xA1, Cr=0x7F]
		 //           ov7670_capture phai ghep: Word0={0x80, 0xA0}, Word1={0x7F, 0xA1}
		 // Ket qua du kien:
		 //   - write_en len 1 sau 2 byte dau tien
		 //   - data_out[15:8] = 0x80 (Cb), data_out[7:0] = 0xA0 (Y0)
		 //   - Sau do data_out = {0x7F, 0xA1}
		 // =========================================================================
		 $display("\n--- TEST 2: OV7670 Capture - YUYV Byte Assembly ---");
		 @(posedge CAM_PCLK);
		 CAM_VSYNC <= 1'b0; CAM_HREF <= 1'b1;
		 // Byte 1: Y0
		 @(posedge CAM_PCLK); CAM_DATA <= 8'hA0;
		 @(posedge CAM_PCLK); CAM_DATA <= 8'h80; // Cb
		 // Cho write_en phat ra sau 2 byte
		 repeat(2) @(posedge CAM_PCLK);
		 check_condition(cam_write_en_dut === 1'b1, "T2.1: write_en = 1 sau 2 byte");
		 check_condition(cam_data_16bit_dut === 16'h80A0, "T2.2: data_out = {Cb,Y0} = 0x80A0");
		 // Byte tiep theo: Y1
		 CAM_DATA <= 8'hA1;
		 @(posedge CAM_PCLK); CAM_DATA <= 8'h7F; // Cr
		 repeat(2) @(posedge CAM_PCLK);
		 check_condition(cam_data_16bit_dut === 16'h7FA1, "T2.3: data_out = {Cr,Y1} = 0x7FA1");
		 // Ket thuc dong
		 CAM_HREF <= 1'b0; CAM_DATA <= 8'd0;
		 repeat(5) @(posedge CAM_PCLK);
		 check_condition(cam_write_en_dut === 1'b0, "T2.4: write_en = 0 khi HREF = 0");

		 // =========================================================================
		 // TEST 3: KIEM TRA YUV422_TO_444 - GIAI MA CHROMA CHINH XAC
		 // Muc dich: Dua vao Word={Cb=0x80, Y0=0xA0} tai iX=0, sau do Word={Cr=0x7F, Y1=0xA1} tai iX=1
		 // Ket qua du kien:
		 //   - iX=0: oY=0xA0, oCb=0x80, oCr=0x80 (oCr giu gia tri truoc)
		 //   - iX=1: oY=0xA1, oCr=0x7F, oCb=0x80 (oCb giu gia tri tu pixel truoc)
		 // =========================================================================
		 $display("\n--- TEST 3: YUV422_to_444 - Chroma Decode ---");
		 @(negedge clk_25m_vga_tb);
		 // Pixel chan (iX=0): Word co Cb
		 yuv422_ix_tb    <= 10'd0;
		 yuv422_input_tb <= 16'h80A0; // [15:8]=Cb=0x80, [7:0]=Y0=0xA0
		 yuv422_valid_tb <= 1'b1;
		 @(posedge clk_25m_vga_tb); // Lenh lap
		 @(posedge clk_25m_vga_tb); // Ket qua o day
		 check_condition(yuv_oY_tb  === 8'hA0, "T3.1: iX=0 -> oY = 0xA0");
		 check_condition(yuv_oCb_tb === 8'h80, "T3.2: iX=0 -> oCb = 0x80");

		 // Pixel le (iX=1): Word co Cr
		 yuv422_ix_tb    <= 10'd1;
		 yuv422_input_tb <= 16'h7FA1; // [15:8]=Cr=0x7F, [7:0]=Y1=0xA1
		 @(posedge clk_25m_vga_tb);
		 @(posedge clk_25m_vga_tb);
		 check_condition(yuv_oY_tb  === 8'hA1, "T3.3: iX=1 -> oY = 0xA1");
		 check_condition(yuv_oCr_tb === 8'h7F, "T3.4: iX=1 -> oCr = 0x7F");
		 check_condition(yuv_oCb_tb === 8'h80, "T3.5: iX=1 -> oCb giu 0x80 (chroma sharing)");
		 yuv422_valid_tb <= 1'b0;

		 // =========================================================================
		 // TEST 4: KIEM TRA SDRAM DOUBLE BUFFER CONTROLLER
		 // Sub-test A: Buffer A hoat dong khi current_buffer=0 (sau reset)
		 // Sub-test B: Luat Avalon MM - giu nguyen khi waitrequest=1
		 // Sub-test C: Lat buffer khi frame_done (VSYNC rising edge)
		 // Ket qua du kien:
		 //   - A: Pixel dau tien ghi vao BUFFER_A_BASE = 0x1000000
		 //   - B: Dia chi va data khong thay doi trong khi waitrequest=1
		 //   - C: Pixel sau frame_done ghi vao BUFFER_B_BASE = 0x104B000
		 // =========================================================================
		 $display("\n--- TEST 4: SDRAM Double Buffer Controller ---");

		 // Reset lai module
		 do_reset;
		 repeat(5) @(posedge clk_50m_sys_tb);
		 w_waitreq_stub    = 1'b0;
		 cam_vsync_stub    = 1'b0;

		 // Sub-test A: Ghi pixel dau tien vao Buffer A
		 sdram_wrdata_stub = 16'hBEEF;
		 @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b1;
		 @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b0;
		 @(posedge clk_50m_sys_tb); // Cho lenh ghi duoc register
		 check_condition(w_addr_dut_tb === 25'h1000000, "T4.1: Pixel dau -> BUFFER_A_BASE=0x1000000");
		 check_condition(w_data_dut_tb === 16'hBEEF,    "T4.2: Data ghi = 0xBEEF");
		 check_condition(w_write_dut_tb === 1'b1,        "T4.3: avm_write = 1");

		 // Sub-test B: Kiem tra luat Avalon waitrequest
		 w_waitreq_stub = 1'b1; // Gia lap SDRAM ban
		 sdram_wrdata_stub = 16'hDEAD;
		 @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b1;
		 @(posedge clk_50m_sys_tb); // Cycle waitrequest
		 // Dia chi va data phai giu nguyen (luat Avalon)
		 @(posedge clk_50m_sys_tb);
		 check_condition(w_write_dut_tb === 1'b1, "T4.4: avm_write giu =1 khi waitrequest=1");
		 check_condition(w_data_dut_tb !== 16'hDEAD, "T4.5: Data khong thay doi khi waitrequest=1");
		 w_waitreq_stub    = 1'b0;
		 sdram_wrreq_stub  = 1'b0;

		 // Sub-test C: Lat buffer sau VSYNC rising edge
		 // Gia lap VSYNC rising edge (LOW -> HIGH)
		 cam_vsync_stub = 1'b0;
		 repeat(5) @(posedge clk_50m_sys_tb);
		 cam_vsync_stub = 1'b1; // Rising edge
		 repeat(5) @(posedge clk_50m_sys_tb);
		 // Ghi pixel moi -> phai vao Buffer B
		 sdram_wrdata_stub = 16'hCAFE;
		 @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b1;
		 @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b0;
		 @(posedge clk_50m_sys_tb);
		 check_condition(w_addr_dut_tb === 25'h104B000 || w_addr_dut_tb === 25'h104B001,
							  "T4.6: Sau VSYNC -> ghi vao BUFFER_B (0x104B000)");
		 cam_vsync_stub = 1'b0;

		 // =========================================================================
		 // TEST 5: KIEM TRA LUONG DU LIEU CAMERA HOAN CHINH (1 DONG)
		 // Muc dich: Phat 1 dong camera 8 pixel, kiem tra so luong write_en
		 // Ket qua du kien:
		 //   - 8 pixel = 16 byte = 8 cap -> 8 lan write_en = 1
		 //   - pixel_counter tang 8 lan
		 // =========================================================================
		 $display("\n--- TEST 5: Camera Line Data Flow (8 pixels) ---");
		 do_reset;
		 pixel_write_count = 0;
		 @(posedge CAM_PCLK);
		 CAM_VSYNC <= 1'b0;
		 repeat(3) @(posedge CAM_PCLK);
		 // Phat 1 dong 8 pixel (= 16 byte YUYV = 8 word)
		 send_camera_line(4, 8'hA0, 8'h80, 8'h80); // 4 cap pixel = 8 pixel total
		 // Cho FIFO va pipeline settle
		 repeat(20) @(posedge CAM_PCLK);
		 repeat(20) @(posedge clk_50m_sys_tb);
		 check_condition(pixel_write_count >= 8, "T5.1: >= 8 write_en sau 1 dong 8 pixel");
		 check_condition(pixel_write_count <= 8, "T5.2: <= 8 write_en (khong ghi du thua)");

		 // =========================================================================
		 // TONG KET KET QUA
		 // =========================================================================
		 $display("\n=================================================");
		 $display("  KET QUA: %0d PASS / %0d FAIL / %0d TOTAL",
					 passed_tests, failed_tests, passed_tests + failed_tests);
		 if (failed_tests == 0)
			  $display("  => TAT CA KIEM THU DAT YEU CAU");
		 else
			  $display("  => CO %0d KIEM THU THAT BAI - CAN XEM XET", failed_tests);
		 $display("=================================================");
		 $display("\n  Thong ke:");
		 $display("  - Tong so pixel write_en tu camera: %0d", pixel_write_count);
		 $display("  - Tong so VGA frame output:         %0d", vga_frame_count);
		 $display("=================================================");

		 #1000;
		 $finish;
	end

	// Timeout bao ve
	initial begin
		 #50000000; // 50ms timeout
		 $display("[TIMEOUT] Testbench qua thoi gian cho phep!");
		 $finish;
	end

	// Ket xuat waveform
	initial begin
		 $dumpfile("tb_doan_top.vcd");
		 $dumpvars(0, tb_doan_top);
	end

endmodule