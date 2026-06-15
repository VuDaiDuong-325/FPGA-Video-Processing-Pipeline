// =============================================================================
// TESTBENCH: tb_doan_top.v
// MUC DICH: Kiem tra toan bo luong du lieu tu Camera OV7670 -> SDRAM -> VGA
// CONG CU:  ModelSim (Verilog-2001 thuan tuy, khong dung SystemVerilog)
// PHUONG PHAP:
//   - Thay the cac module hardware (PLL, SDRAM, FIFO, Qsys) bang Stub/Model
//   - Kiem tra 5 test case doc lap
// =============================================================================
`timescale 1ns / 1ps

module tb_doan_top;

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
time    t_h1, t_h2;
integer h_cycles;
integer v_lines;

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
reg [10:0] vga_fifo_wrusedw_tb;

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

// Cho sdram_read_controller
reg         r_frame_done_tb;
wire [24:0] r_avm_addr_tb;
wire        r_avm_read_tb;
reg         r_avm_waitrequest_tb;
reg  [15:0] r_avm_readdata_tb;
reg         r_avm_readdatavalid_tb;
wire        vga_fifo_wrreq_tb;
wire [15:0] vga_fifo_wrdata_tb;

// --- Kiem tra module sdram_read_controller ---
sdram_read_controller u_sdram_read_dut (
    .clk                (clk_50m_sys_tb),
    .rst_n              (KEY[0]),
    .frame_done         (r_frame_done_tb),
    .avm_address        (r_avm_addr_tb),
    .avm_read           (r_avm_read_tb),
    .avm_waitrequest    (r_avm_waitrequest_tb),
    .avm_readdata       (r_avm_readdata_tb),
    .avm_readdatavalid  (r_avm_readdatavalid_tb),
    .fifo_wrreq         (vga_fifo_wrreq_tb),
    .fifo_wrdata        (vga_fifo_wrdata_tb),
    .fifo_wrusedw       (vga_fifo_wrusedw_tb)
);

// Cho VGA_Image_Processor
reg  [1:0]  img_proc_mode_tb;
reg         img_proc_valid_tb;
reg  [7:0]  img_proc_y_tb;
reg  [7:0]  img_proc_cb_tb;
reg  [7:0]  img_proc_cr_tb;
wire [9:0]  img_proc_r_tb;
wire [9:0]  img_proc_g_tb;
wire [9:0]  img_proc_b_tb;

// --- Kiem tra module VGA_Image_Processor ---
VGA_Image_Processor u_image_processor_dut (
    .iCLK    (clk_25m_vga_tb),
    .iRST_N  (KEY[0]),
    .iMode   (img_proc_mode_tb),
    .i_valid (img_proc_valid_tb),
    .iY      (img_proc_y_tb),
    .iCb     (img_proc_cb_tb),
    .iCr     (img_proc_cr_tb),
    .oRed    (img_proc_r_tb),
    .oGreen  (img_proc_g_tb),
    .oBlue   (img_proc_b_tb)
);

// Cho VGA_controller
wire [10:0] vga_x_tb;
wire [10:0] vga_y_tb;
wire [21:0] vga_addr_tb;
wire        vga_req_tb;

// --- Kiem tra module VGA_controller ---
VGA_controller u_vga_dut (
    .iCLK       (clk_25m_vga_tb),
    .iRST_N     (KEY[0]),
    .iRed       (10'd512), // Data màu giả lập (Ảnh gốc)
    .iGreen     (10'd256),
    .iBlue      (10'd128),
    .oCurrent_X (vga_x_tb),
    .oCurrent_Y (vga_y_tb),
    .oAddress   (vga_addr_tb),
    .oRequest   (vga_req_tb),
    .oVGA_R     (VGA_R),
    .oVGA_G     (VGA_G),
    .oVGA_B     (VGA_B),
    .oVGA_HS    (VGA_HS),
    .oVGA_VS    (VGA_VS),
    .oVGA_SYNC  (VGA_SYNC_N),
    .oVGA_BLANK (VGA_BLANK_N),
    .oVGA_CLOCK (VGA_CLK)
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
    input [2047:0] test_name;
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
	 r_frame_done_tb        = 0;
    r_avm_waitrequest_tb   = 0;
    r_avm_readdata_tb      = 16'd0;
    r_avm_readdatavalid_tb = 0;
    vga_fifo_wrusedw_tb    = 11'd0; // FIFO rỗng ban đầu, cần đọc thêm dữ liệu

    img_proc_mode_tb       = 2'b00;
    img_proc_valid_tb      = 0;
    img_proc_y_tb          = 8'd0;
    img_proc_cb_tb         = 8'd0;
    img_proc_cr_tb         = 8'd0;
	 

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
    
    // Bước 1: Ép các tín hiệu ngõ ra lên giá trị khác 0 trước khi bấm Reset
    force cam_write_en_dut = 1'b1;
    force w_write_dut_tb   = 1'b1;
    force w_addr_dut_tb    = 25'h1ABCDEF; // Đặt một địa chỉ rác bất kỳ
    
    #10; // Chờ 10ns để giá trị rác này kịp hiển thị rõ ràng trên dạng sóng (Waveform)

    // Bước 2: Bấm nút nhấn Reset (Kéo KEY[0] xuống mức 0)
    KEY[0] <= 1'b0;
    
    // Giữ nút nhấn trong 5 chu kỳ xung nhịp để trạng thái reset ngấm vào hệ thống
    repeat(5) @(posedge CLOCK_50); 
    
    // Bước 3: NHẢ LỆNH ÉP (release) trong khi nút Reset vẫn đang được nhấn giữ
    // Lúc này, Testbench không can thiệp nữa, nhường quyền điều khiển lại cho DUT.
    // Vì KEY[0] vẫn đang bằng 0, mạch nội bộ của các DUT phải tự động kéo các ngõ ra về 0.
    release cam_write_en_dut;
    release w_write_dut_tb;
    release w_addr_dut_tb;
    
    // Giữ nút nhấn reset thêm 5 chu kỳ nữa cho đủ thời gian ổn định
    repeat(5) @(posedge CLOCK_50);
    
    // Bước 4: Nhả nút Reset (Đưa KEY[0] lên mức 1 để hệ thống bắt đầu chạy)
    KEY[0] <= 1'b1;
    repeat(5) @(posedge CLOCK_50); 
    
    // Đợi thêm 5 chu kỳ clock hệ thống để mạch đồng bộ hoàn toàn
    repeat(5) @(posedge clk_50m_sys_tb);
    
    // Bước 5: Tiến hành kiểm tra điều kiện nghiêm ngặt
    check_condition(cam_write_en_dut === 1'b0,   "T1.1: cam_write_en = 0 sau Reset");
    check_condition(w_write_dut_tb   === 1'b0,   "T1.2: avm_write = 0 thực sự nhờ Reset");
    check_condition(w_addr_dut_tb    === 25'd0,  "T1.3: avm_address = 0 thực sự nhờ Reset");

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

    // Reset sach trang thai truoc
    CAM_VSYNC <= 1'b0; CAM_HREF <= 1'b0; CAM_DATA <= 8'd0;
    repeat(3) @(posedge CAM_PCLK);

    // ---- Mo phong dung timeline camera OV7670 ----
    // OV7670 dat HREF=1 VA DATA=Y0 CUNG LUC (cung cycle)
    // Module ov7670_capture: khi href_reg_OLD=0 -> reset, d_reg nhan Y0
    // Cycle tiep: href_reg=1, bf=0 -> latched = d_reg = Y0
    // Cycle tiep: bf=1, d_reg=Cb   -> data_out = {Cb, Y0} = 0x80A0, write_en=1
    //
    // Sequence: dat HREF+DATA tai negedge, doc ket qua sau 3 posedge
    @(negedge CAM_PCLK);
    CAM_HREF <= 1'b1;   // HREF len cung luc voi byte dau tien
    CAM_DATA <= 8'hA0;  // Y0 - byte 0 (cam dung lam "d_reg seed")
    @(posedge CAM_PCLK); // T0: href_reg_old=0->reset, d_reg<-Y0

    @(negedge CAM_PCLK); CAM_DATA <= 8'h80; // Cb - byte 1
    @(posedge CAM_PCLK); // T1: href_reg=1, bf_old=0 -> latched_data=Y0, bf<-1

    @(negedge CAM_PCLK); CAM_DATA <= 8'hA1; // Y1 - byte 2 (can thiet de d_reg chua Cb)
    @(posedge CAM_PCLK); // T2: bf_old=1, d_reg=Cb -> data_out={Cb,Y0}=0x80A0, we=1
    #1;
    check_condition(cam_write_en_dut === 1'b1,       "T2.1: write_en = 1 sau 2 byte");
    check_condition(cam_data_16bit_dut === 16'h80A0, "T2.2: data_out = {Cb,Y0} = 0x80A0");

    // Tiep tuc: Cr -> data_out = {Cr, Y1} = 0x7FA1
    @(negedge CAM_PCLK); CAM_DATA <= 8'h7F; // Cr - byte 3
    @(posedge CAM_PCLK); // T3: latch Y1
    @(negedge CAM_PCLK); CAM_DATA <= 8'hA2; // Y2 - byte 4 (de d_reg nap Cr)
    @(posedge CAM_PCLK); // T4: data_out={Cr,Y1}=0x7FA1, we=1
    #1;
    check_condition(cam_data_16bit_dut === 16'h7FA1, "T2.3: data_out = {Cr,Y1} = 0x7FA1");

    // Ket thuc dong
    @(negedge CAM_PCLK); CAM_HREF <= 1'b0; CAM_DATA <= 8'd0;
    @(posedge CAM_PCLK);
    @(posedge CAM_PCLK);
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

    // Sub-test B: Kiem tra luat Avalon - waitrequest PHAI duoc set TRUOC khi pixel valid
    // Scenario: SDRAM bat ngo ban TRONG khi dang ghi pixel BEEF
    // -> waitrequest=1 set tai negedge (truoc posedge), CUNG luc pixel_valid=1
    // -> DUT phai HOLD toan bo bus, khong chap nhan data moi (DEAD)
    @(negedge clk_50m_sys_tb); w_waitreq_stub = 1'b1; // Set waitreq tai negedge
    sdram_wrdata_stub = 16'hBEEF;                      // Data moi muon ghi
    @(posedge clk_50m_sys_tb); sdram_wrreq_stub = 1'b1; // Cycle nay: write=1, waitreq=1 -> HOLD
    @(posedge clk_50m_sys_tb);                           // Kiem tra HOLD con hieu luc
    // Doi FIFO thay doi data trong khi DUT dang bi hold
    sdram_wrdata_stub = 16'hDEAD;
    @(posedge clk_50m_sys_tb);
    check_condition(w_write_dut_tb === 1'b1,      "T4.4: avm_write giu =1 khi waitrequest=1");
    check_condition(w_data_dut_tb === 16'hBEEF,   "T4.5: Data giu BEEF, khong doi sang DEAD");
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
    // --- TEST 6: SDRAM Read Controller Verification ---
    // =========================================================================
    $display("\n--- TEST 6: SDRAM Read Controller Verification ---");
    do_reset;
    
    // T6.1: Kiểm tra tự động phát lệnh đọc khi khởi tạo
    vga_fifo_wrusedw_tb  <= 11'd100; // FIFO mới chứa 100 từ (< 1024)
    r_avm_waitrequest_tb <= 1'b0;
    
    // Kích hoạt tín hiệu bắt đầu chu kỳ đọc mới
    @(posedge clk_50m_sys_tb);
    r_frame_done_tb <= 1'b1;
    @(posedge clk_50m_sys_tb);
    r_frame_done_tb <= 1'b0;
    
    repeat(2) @(posedge clk_50m_sys_tb);
    check_condition(r_avm_read_tb === 1'b1, "T6.1: Tu dong phat avm_read=1 de doi du lieu tu SDRAM");

    // T6.2 & T6.3: Kiểm tra nhận dữ liệu Valid từ SDRAM và đẩy vào FIFO
    @(negedge clk_50m_sys_tb);
    r_avm_readdata_tb      <= 16'hCAFE;
    r_avm_readdatavalid_tb <= 1'b1;
    @(posedge clk_50m_sys_tb);
    #1; // Chờ mạch nạp kết quả
    check_condition(vga_fifo_wrreq_tb === 1'b1, "T6.2: Co du lieu valid tu SDRAM -> kick hoat fifo_wrreq");
    check_condition(vga_fifo_wrdata_tb === 16'hCAFE, "T6.3: Du lieu giu dung gia tri mang vao FIFO (0xCAFE)");
    
    @(negedge clk_50m_sys_tb);
    r_avm_readdatavalid_tb <= 1'b0;

    // [BỔ SUNG] T6.4: Kiểm tra cơ chế giữ Bus Avalon-MM khi gặp waitrequest = 1
    @(negedge clk_50m_sys_tb);
    r_avm_waitrequest_tb <= 1'b1; // Ép SDRAM báo bận
    @(posedge clk_50m_sys_tb);
    
    // (SỬA LỖI UNNAMED BLOCK Ở ĐÂY): Đặt tên block là "t6_locked_addr"
    begin : t6_locked_addr
        reg [24:0] locked_addr;
        locked_addr = r_avm_addr_tb;
        repeat(2) @(posedge clk_50m_sys_tb); // Chờ qua 2 chu kỳ clock
        #1;
        check_condition(r_avm_read_tb === 1'b1 && r_avm_addr_tb === locked_addr, 
                        "T6.4: [NANG CAO] Giu nguyen avm_read va avm_address khi waitrequest = 1");
    end
    @(negedge clk_50m_sys_tb);
    r_avm_waitrequest_tb <= 1'b0; // Giải phóng bận
    @(posedge clk_50m_sys_tb);

    // [BỔ SUNG] T6.5: Kiểm tra ngưỡng chặn chống tràn FIFO (FIFO_THRESHOLD = 1024)
    @(negedge clk_50m_sys_tb);
    vga_fifo_wrusedw_tb <= 11'd1600; // Giả lập FIFO chứa vượt ngưỡng 1536 từ
    repeat(2) @(posedge clk_50m_sys_tb);
    #1;
    check_condition(r_avm_read_tb === 1'b0, "T6.5: [NANG CAO] Tu dong ngat avm_read khi FIFO vuot nguong 1536");
    
    // [BỔ SUNG] T6.6: Kiểm tra reset bộ đếm địa chỉ khi nhận xung kết thúc khung hình
    @(negedge clk_50m_sys_tb);
    vga_fifo_wrusedw_tb <= 11'd500; // Cho phép đọc lại
    r_frame_done_tb     <= 1'b1;    // Báo kết thúc khung hình
    @(posedge clk_50m_sys_tb);
    r_frame_done_tb     <= 1'b0;
    @(posedge clk_50m_sys_tb);
    #1;
    check_condition(r_avm_addr_tb === 25'h104B000, "T6.6: [NANG CAO] Reset dia chi doc ve Base Address sau frame_done");


    // =========================================================================
    // --- TEST 7: VGA Image Processor MUX & Pipeline (Đã sửa đổi) ---
    // =========================================================================
    $display("\n--- TEST 7: VGA Image Processor MUX & Pipeline ---");
    // Chuyển sang miền clock VGA 25MHz
    @(negedge clk_25m_vga_tb);
    
    // Thiết lập dữ liệu YUV đầu vào cố định ban đầu
    img_proc_valid_tb <= 1'b1;
    img_proc_y_tb     <= 8'hA0;
    img_proc_cb_tb    <= 8'h80;
    img_proc_cr_tb    <= 8'h7F;
    
    // Chế độ 00: Kiểm tra ảnh màu RGB gốc
    img_proc_mode_tb  <= 2'b00; 
    repeat(3) @(posedge clk_25m_vga_tb); // Chờ qua pipeline trễ
    #1;
    $display("[INFO] Mode 00 - Output RGB: R=%0d, G=%0d, B=%0d", img_proc_r_tb, img_proc_g_tb, img_proc_b_tb);
    check_condition(img_proc_r_tb !== 10'dX && img_proc_g_tb !== 10'dX && img_proc_b_tb !== 10'dX, 
                    "T7.1: Mode 00 xuat tin hieu RGB hop le (khong bi loi X)");

    // Chế độ 01: Kiểm tra thuật toán ảnh xám (Grayscale)
    @(negedge clk_25m_vga_tb);
    img_proc_mode_tb  <= 2'b01;
    repeat(3) @(posedge clk_25m_vga_tb);
    #1;
    check_condition((img_proc_r_tb === img_proc_g_tb) && (img_proc_g_tb === img_proc_b_tb), 
                    "T7.2: Mode Grayscale thanh cong - anh R, G, B can bang tuyet doi");

    // [BỔ SUNG] T7.3: Kiểm tra chuyển đổi chế độ động (Dynamic Runtime Switching)
    // Giả lập trạng thái pixel đang truyền liên tục và người dùng gạt Switch đột ngột
    @(negedge clk_25m_vga_tb);
    img_proc_mode_tb  <= 2'b00; // Quay lại chế độ màu
    @(posedge clk_25m_vga_tb);
    
    @(negedge clk_25m_vga_tb);
    img_proc_y_tb     <= 8'hFF; // Đang truyền, pixel sáng rực lên
    @(posedge clk_25m_vga_tb);
    
    @(negedge clk_25m_vga_tb);
    img_proc_mode_tb  <= 2'b01; // Người dùng đột ngột gạt switch sang ảnh xám
    repeat(3) @(posedge clk_25m_vga_tb); // Đợi qua Pipeline
    #1;
    check_condition((img_proc_r_tb === img_proc_g_tb) && (img_proc_g_tb === img_proc_b_tb), 
                    "T7.3: [NANG CAO] Bo MUX dap ung chuyen doi che do dung timing, khong gay giat hinh");
                    
    @(negedge clk_25m_vga_tb);
    img_proc_valid_tb <= 1'b0;
	 
	 // =========================================================================
    // TEST 8: KIEM TRA VGA CONTROLLER (Timing, Pipeline & Test Pattern)
    // =========================================================================
    $display("\n--- TEST 8: VGA Controller Timing & Feature Verification ---");
    do_reset;
    
    // T8.1: Đo H_TOTAL (800)
    @(negedge VGA_HS);
    t_h1 = $time;
    @(negedge VGA_HS);
    t_h2 = $time;
    h_cycles = (t_h2 - t_h1) / CLK25_PERIOD; 
    check_condition(h_cycles == 800, "T8.1: H_TOTAL = 800 xung clock 25MHz (640x480 chuan)");

    // T8.2: Kiểm tra ép màu đen (Blanking) ngoài vùng hiển thị
    // Chờ đến lúc oRequest = 0 (Đang quét trong vùng Blanking)
    wait(vga_req_tb == 1'b0);
    repeat(5) @(posedge clk_25m_vga_tb); // Đợi 4 nhịp delay của Pipeline
    check_condition(VGA_R === 10'd0 && VGA_G === 10'd0 && VGA_B === 10'd0, 
                    "T8.2: Mau RGB tu dong bi ep ve 0 (Den) trong vung Blanking");

    // T8.3: Kiểm tra chức năng nhúng Test Pattern (Dấu thập đỏ)
    // Chờ quét tới tọa độ X=320 (Vạch đỏ)
    wait(vga_x_tb == 11'd320 && vga_req_tb == 1'b1);
    repeat(3) @(posedge clk_25m_vga_tb); // Đợi tọa độ truyền vào logic đổi màu
    check_condition(VGA_R === 10'h3FF && VGA_G === 10'd0, 
                    "T8.3: Test Pattern tao vach Mau Do (R=3FF) tai toa do X=320");

    // T8.4: Kiểm tra hiển thị ảnh thật khi không chạm vạch Test Pattern
    wait(vga_x_tb == 11'd321 && vga_req_tb == 1'b1); // Thoát khỏi vạch đỏ
    repeat(3) @(posedge clk_25m_vga_tb);
    check_condition(VGA_R === 10'd512 && VGA_G === 10'd256, 
                    "T8.4: Mau anh goc (512,256) duoc giu nguyen khi khong nam tren vach Test");

    // T8.5: Đo V_TOTAL (525 dòng) - Quá trình này mô phỏng tốn khoảng ~16ms time
    begin : count_v_lines
        v_lines = 0;
        @(negedge VGA_VS); 
        fork
            begin
                @(negedge VGA_VS);
                disable count_v_lines; 
            end
            begin
                forever begin
                    @(negedge VGA_HS);
                    v_lines = v_lines + 1;
                end
            end
        join
    end
    check_condition(v_lines == 525, "T8.5: V_TOTAL = 525 dong quet (Chuan VESA 60Hz)");
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