// ov7670_config.v
// Fixes applied:
//   1. rom_data[6] = 16'h00  →  8'h00  (width mismatch on 8-bit array element)
//   2. Expanded register table to the minimum set needed for
//      reliable RGB-565 VGA output at 640x480 30 fps.

module ov7670_config (
    input  wire clk_i,       // 50 MHz system clock
    input  wire rst_n_i,     // Active-low reset
    output wire sioc_o,      // SCCB clock → CAM_SIOC
    inout  wire siod_io,     // SCCB data  → CAM_SIOD
    output reg  done_o       // High when all registers have been written
);

    reg        start_r;
    reg [7:0]  reg_addr_r;
    reg [7:0]  reg_data_r;
    wire       ready_w;

    sccb_master u_sccb (
        .clk_i      (clk_i),
        .rst_n_i    (rst_n_i),
        .start_i    (start_r),
        .reg_addr_i (reg_addr_r),
        .reg_data_i (reg_data_r),
        .ready_o    (ready_w),
        .sioc_o     (sioc_o),
        .siod_io    (siod_io)
    );

    // -----------------------------------------------------------------
    // Register table for OV7670 – RGB565 VGA 640×480 @ 30 fps
    //
    // Key registers (datasheet Table 5):
    //   0x12 COM7    : 0x80 = soft reset (always first)
    //   0x12 COM7    : 0x04 = RGB mode, VGA (bit2=1 → RGB, bit0=0 → not raw)
    //   0x40 COM15   : 0xD0 = full output range [00..FF], RGB565 (bits[5:4]=01)
    //   0x11 CLKRC   : 0x00 = use XCLK directly, 30 fps
    //   0x0C COM3    : 0x00 = scale disabled, DCW disabled
    //   0x3E COM14   : 0x00 = PCLK not divided, scaling PCLK disabled
    //   0x15 COM10   : 0x00 = PCLK free-running, no polarity inversion
    //   0x1E MVFP    : 0x07 = no mirror/flip, black-sun enable
    //   0x32 HREF    : 0x80 = default HREF timing
    //   0x17 HSTART  : 0x13 = horizontal start (typical for VGA RGB)
    //   0x18 HSTOP   : 0x01 = horizontal stop
    //   0x19 VSTRT   : 0x02 = vertical start
    //   0x1A VSTOP   : 0x7A = vertical stop
    //   0x03 VREF    : 0x0A = VREF low bits
    //   0x3A TSLB    : 0x04 = YUV sequence / auto output window
    //   0x3D COM13   : 0x88 = gamma enable, UV saturation auto
    // -----------------------------------------------------------------
    localparam TOTAL_REGS = 16;

    reg [7:0] rom_addr [0:TOTAL_REGS-1];
    reg [7:0] rom_data [0:TOTAL_REGS-1]; // FIX #1: all entries are 8-bit

    initial begin
        // Step 0: Software reset – must be sent first and then wait
        rom_addr[0]  = 8'h12; rom_data[0]  = 8'h80;

        // Step 1: Output format – RGB, VGA resolution
        rom_addr[1]  = 8'h12; rom_data[1]  = 8'h04;

        // Step 2: COM15 – full output range, RGB565
        rom_addr[2]  = 8'h40; rom_data[2]  = 8'hD0;

        // Step 3: CLKRC – no pre-scaler (30 fps with 24 MHz XCLK)
        rom_addr[3]  = 8'h11; rom_data[3]  = 8'h00;

        // Step 4: COM3 – scale & DCW off
        rom_addr[4]  = 8'h0C; rom_data[4]  = 8'h00;

        // Step 5: COM14 – PCLK not divided
        rom_addr[5]  = 8'h3E; rom_data[5]  = 8'h00;

        // Step 6: COM10 – PCLK free running, VSYNC/HREF normal polarity
        //   FIX: was 16'h00 (wrong width) → now 8'h00
        rom_addr[6]  = 8'h15; rom_data[6]  = 8'h00;

        // Step 7: MVFP – no mirror, no flip
        rom_addr[7]  = 8'h1E; rom_data[7]  = 8'h07;

        // Step 8-12: Window timing for clean 640×480 RGB frame
        rom_addr[8]  = 8'h32; rom_data[8]  = 8'h80;
        rom_addr[9]  = 8'h17; rom_data[9]  = 8'h13;
        rom_addr[10] = 8'h18; rom_data[10] = 8'h01;
        rom_addr[11] = 8'h19; rom_data[11] = 8'h02;
        rom_addr[12] = 8'h1A; rom_data[12] = 8'h7A;
        rom_addr[13] = 8'h03; rom_data[13] = 8'h0A;

        // Step 14: TSLB – auto output window
        rom_addr[14] = 8'h3A; rom_data[14] = 8'h04;

        // Step 15: COM13 – gamma on, UV saturation auto
        rom_addr[15] = 8'h3D; rom_data[15] = 8'h88;
    end

    // -----------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------
    localparam ST_INIT_DELAY = 2'd0;
    localparam ST_START      = 2'd1;
    localparam ST_WAIT       = 2'd2;
    localparam ST_DONE       = 2'd3;

    reg [1:0]  state_r;
    reg [5:0]  rom_idx_r;
    reg [23:0] delay_cnt_r;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r     <= ST_INIT_DELAY;
            rom_idx_r   <= 6'd0;
            delay_cnt_r <= 24'd0;
            start_r     <= 1'b0;
            reg_addr_r  <= 8'd0;
            reg_data_r  <= 8'd0;
            done_o      <= 1'b0;
        end else begin
            case (state_r)

                // Wait ~15 ms at 50 MHz before starting (750 000 cycles)
                ST_INIT_DELAY: begin
                    start_r <= 1'b0;
                    if (delay_cnt_r == 24'd750_000) begin
                        delay_cnt_r <= 24'd0;
                        state_r     <= ST_START;
                    end else begin
                        delay_cnt_r <= delay_cnt_r + 1'b1;
                    end
                end

                ST_START: begin
                    if (rom_idx_r == TOTAL_REGS) begin
                        state_r <= ST_DONE;
                    end else if (ready_w) begin
                        reg_addr_r <= rom_addr[rom_idx_r];
                        reg_data_r <= rom_data[rom_idx_r];
                        start_r    <= 1'b1;
                        state_r    <= ST_WAIT;
                    end
                end

                ST_WAIT: begin
                    start_r <= 1'b0;
                    if (ready_w) begin
                        // After the soft-reset (index 0), insert an extra
                        // 15 ms delay for the camera to finish resetting.
                        if (rom_idx_r == 6'd0) begin
                            delay_cnt_r <= 24'd0;
                            rom_idx_r   <= rom_idx_r + 1'b1;
                            state_r     <= ST_INIT_DELAY;
                        end else begin
                            rom_idx_r   <= rom_idx_r + 1'b1;
                            state_r     <= ST_START;
                        end
                    end
                end

                ST_DONE: begin
                    done_o  <= 1'b1;
                    start_r <= 1'b0;
                end

                default: state_r <= ST_INIT_DELAY;
            endcase
        end
    end

endmodule