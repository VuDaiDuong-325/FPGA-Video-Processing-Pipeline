// =========================================================================
// TESTBENCH SIÊU TỐC: Đã thu nhỏ mốc FULL xuống 3072 pixel (1/100 khung hình)
// =========================================================================

`timescale 1ns/1ps

module debug_top_tb;
    reg        tb_CLOCK_50;
    reg  [3:0] tb_KEY;
    reg  [9:0] tb_SW;
    reg        tb_CAM_PCLK;
    reg        tb_CAM_VSYNC;
    reg        tb_CAM_HREF;
    reg  [7:0] tb_CAM_DATA;

    wire [9:0] tb_LEDR;
    wire [12:0] tb_DRAM_ADDR;
    wire [1:0]  tb_DRAM_BA;
    wire        tb_DRAM_CAS_N;
    wire        tb_DRAM_CKE;
    wire        tb_DRAM_CLK;
    wire        tb_DRAM_CS_N;
    wire        tb_DRAM_LDQM;
    wire        tb_DRAM_RAS_N;
    wire        tb_DRAM_UDQM;
    wire        tb_DRAM_WE_N;
    
    wire [15:0] tb_DRAM_DQ;
    assign tb_DRAM_DQ = 16'hZZZZ; 

    integer total_errors = 0;

    debug_top uut (
        .CLOCK_50   (tb_CLOCK_50),
        .KEY        (tb_KEY),
        .SW         (tb_SW),
        .LEDR       (tb_LEDR),
        .DRAM_ADDR  (tb_DRAM_ADDR),
        .DRAM_BA    (tb_DRAM_BA),
        .DRAM_CAS_N (tb_DRAM_CAS_N),
        .DRAM_CKE   (tb_DRAM_CKE),
        .DRAM_CLK   (tb_DRAM_CLK),
        .DRAM_CS_N  (tb_DRAM_CS_N),
        .DRAM_DQ    (tb_DRAM_DQ),
        .DRAM_LDQM  (tb_DRAM_LDQM),
        .DRAM_RAS_N (tb_DRAM_RAS_N),
        .DRAM_UDQM  (tb_DRAM_UDQM),
        .DRAM_WE_N  (tb_DRAM_WE_N),
        .CAM_PCLK   (tb_CAM_PCLK),
        .CAM_VSYNC  (tb_CAM_VSYNC),
        .CAM_HREF   (tb_CAM_HREF),
        .CAM_DATA   (tb_CAM_DATA)
    );

    initial tb_CLOCK_50 = 1'b0;
    always #10 tb_CLOCK_50 = ~tb_CLOCK_50; // 50MHz

    initial tb_CAM_PCLK = 1'b0;
    always #40 tb_CAM_PCLK = ~tb_CAM_PCLK;  // 12.5MHz

    initial begin
        tb_KEY       = 4'b1111; 
        tb_SW        = 10'd0;   
        tb_CAM_VSYNC = 1'b0;
        tb_CAM_HREF  = 1'b0;
        tb_CAM_DATA  = 8'h00;

        $display("\n============================================================");
        $display("[TIME: %0t] --- FAST VERIFICATION (3072 PIXELS) STARTED ---", $time);
        $display("============================================================\n");
        
        #100; tb_KEY[0] = 1'b0; 
        #200; tb_KEY[0] = 1'b1; 

        // CASE 1: SDRAM INIT
        $display("[TIME: %0t] >>> CASE 1: Testing SDRAM Initialization (Wait 400us)...", $time);
        #400000; 

        // CASE 2: WRITE 10 PIXELS
        $display("\n[TIME: %0t] >>> CASE 2: Switch to Real Camera & Write 10 Pixels...", $time);
        tb_SW[0] = 1'b1; #2000;
        
        @(negedge tb_CAM_PCLK); tb_CAM_VSYNC = 1'b1; 
        repeat(3) @(negedge tb_CAM_PCLK); tb_CAM_VSYNC = 1'b0;
        repeat(10) @(negedge tb_CAM_PCLK);

        sim_raw_pixels(10);
        #5000; 

        if (uut.u_write_ctrl.pixel_counter === 19'd10) $display("  -> [PASSED] 10 pixels written.");
        else begin $display("  -> [FAILED]"); total_errors = total_errors + 1; end

        // CASE 3: WRITE FULL & OVER-WRITE PROTECTION
        $display("\n[TIME: %0t] >>> CASE 3: Pumping data until Frame Buffer is FULL (3072)...", $time);
        sim_raw_pixels(3072 - 10); // Bơm 3062 pixel còn lại cho đầy mức 3072
        #20000; // Tăng thời gian chờ cho data chảy hết từ FIFO ra SDRAM

        if (uut.u_write_ctrl.pixel_counter === 19'd3072) $display("  -> [PASSED] Buffer FULL at 3072 pixels.");
        else begin $display("  -> [FAILED]"); total_errors = total_errors + 1; end

        $display("[TIME: %0t]     -> Forcing 5 more pixels into FULL buffer...", $time);
        sim_raw_pixels(5);
        #5000;

        if (uut.u_write_ctrl.pixel_counter === 19'd3072) $display("  -> [PASSED] Over-write protection works! Counter stuck at 3072.");
        else begin $display("  -> [FAILED] Danger! Overwritten."); total_errors = total_errors + 1; end

        // CASE 4: READ EMPTY & OVER-READ PROTECTION
        $display("\n[TIME: %0t] >>> CASE 4: Simulating Buffer Swap & Reading out SDRAM...", $time);
        
        @(negedge tb_CAM_PCLK); tb_CAM_VSYNC = 1'b1; 
        repeat(3) @(negedge tb_CAM_PCLK); tb_CAM_VSYNC = 1'b0;

        force uut.u_sdram_to_vga_fifo.rdreq = ~uut.u_sdram_to_vga_fifo.rdempty;

        force uut.vga_frame_done = 1'b1; #50; 
        force uut.vga_frame_done = 1'b0;

        $display("[TIME: %0t]     -> Waiting for Read Controller to fetch 3072 pixels...", $time);
        
        begin : READ_WAIT_BLOCK
            fork
                begin
                    wait(uut.u_read_ctrl.req_cnt == 19'd3072);
                    disable READ_WAIT_BLOCK; 
                end
                begin
                    #5000000; // Timeout an toàn 5ms
                    $display("  -> [TIMEOUT WARNING] Reading hung!");
                    disable READ_WAIT_BLOCK; 
                end
            join
        end

        if (uut.u_read_ctrl.req_cnt === 19'd3072) $display("  -> [PASSED] Successfully fetched exactly 3072 pixels.");
        else begin $display("  -> [FAILED]"); total_errors = total_errors + 1; end

        $display("[TIME: %0t]     -> Waiting longer to see if it reads more...", $time);
        #10000; 

        if (uut.u_read_ctrl.req_cnt === 19'd3072 && uut.u_read_ctrl.avm_read === 1'b0) $display("  -> [PASSED] Over-read protection works! Safe at 3072.");
        else begin $display("  -> [FAILED]"); total_errors = total_errors + 1; end

        release uut.u_sdram_to_vga_fifo.rdreq;

        $display("\n============================================================");
        if (total_errors == 0) $display(" FINAL VERDICT: EXCELLENT! 100%% PASSED.");
        else $display(" FINAL VERDICT: FAILED WITH %0d ERRORS.", total_errors);
        $display("============================================================\n");

        $stop; 
    end

    task sim_raw_pixels;
        input integer count;
        integer i;
        begin
            @(negedge tb_CAM_PCLK);
            tb_CAM_HREF = 1'b1;
            for (i = 0; i < count; i = i + 1) begin
                tb_CAM_DATA = 8'hAA; @(negedge tb_CAM_PCLK);
                tb_CAM_DATA = 8'h55; @(negedge tb_CAM_PCLK);
            end
            tb_CAM_HREF = 1'b0;
            tb_CAM_DATA = 8'h00;
        end
    endtask

endmodule