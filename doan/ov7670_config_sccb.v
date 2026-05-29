module ov7670_config_sccb(
    // System signals
    input  wire iCLK,       // System clock (e.g., 50MHz)
    input  wire iRST_N,     // Active-low reset
    input  wire iSTART,     // Pulse to start configuration
    
    // SCCB signals (to OV7670)
    output wire oSCLK,      // Serial clock
    inout  wire oSDA,       // Serial data
    
    // Status signal
    output reg  config_done // Goes high when all registers are configured
);

    //==========================================================================
    // Parameters & State Definitions
    //==========================================================================
    // Clock divider parameters
    parameter CLK_Freq   = 50_000_000;
    parameter SCLK_Freq  = 400_000;
    parameter DIV_FACTOR = CLK_Freq / SCLK_Freq;
    
    // FSM States
    localparam IDLE              = 4'd0;
    localparam START             = 4'd1;
    localparam WRITE_DEVICE_ADDR = 4'd2;
    localparam ACK1              = 4'd3;
    localparam WRITE_REG_ADDR    = 4'd4;
    localparam ACK2              = 4'd5;
    localparam WRITE_DATA        = 4'd6;
    localparam ACK3              = 4'd7;
    localparam STOP              = 4'd8;
    localparam DELAY             = 4'd9;
    localparam DONE              = 4'd10;
    
    // OV7670 Write Address
    localparam CAMERA_WRITE_ADDR = 8'h42;
    
    // Total number of registers to configure (Updated for new LUT)
    localparam LUT_SIZE = 166; 
    
    //==========================================================================
    // Internal Signals
    //==========================================================================
    reg [3:0]  state;
    reg [15:0] timer;          // Clock divider counter
    reg [1:0]  phase;          // 4 phases per SCLK cycle
    reg        sclk_reg;
    reg        sda_out;        // SDA output value
    reg        sda_out_en;     // SDA direction control (1: Output, 0: High-Z/Input)
    
    reg [7:0]  lut_index;      // Current LUT entry index
    wire [15:0] lut_data;      // Output from external LUT module {RegAddr, Data}
    reg [7:0]  shift_reg;      // Data to be shifted out
    reg [3:0]  bit_count;      // Counts bits shifted (0 to 7)
    reg [19:0] delay_cnt;      // Delay counter between commands
    
    // Tri-state buffer for SDA
    assign oSDA  = (sda_out_en) ? sda_out : 1'bz;
    assign oSCLK = sclk_reg;
    
    //==========================================================================
    // Instantiate External Configuration LUT
    //==========================================================================
    sccb_ov7670_lut_config u_lut_config (
        .lut_index (lut_index),
        .lut_data  (lut_data)
    );

    //==========================================================================
    // Main FSM & Timing Controller
    //==========================================================================
    always @(posedge iCLK) begin
        if (!iRST_N) begin
            // Reset all logic
            state       <= IDLE;
            timer       <= 16'd0;
            phase       <= 2'd0;
            sclk_reg    <= 1'b1;
            sda_out     <= 1'b1;
            sda_out_en  <= 1'b1;
            config_done <= 1'b0;
            lut_index   <= 8'd0;
            bit_count   <= 4'd0;
            delay_cnt   <= 20'd0;
        end 
        else begin
            // Base Tick Generation (4 ticks per SCLK cycle)
            if (state != IDLE && state != DELAY && state != DONE) begin
                if (timer < (DIV_FACTOR/4 - 1)) begin
                    timer <= timer + 1'b1;
                end 
                else begin
                    timer <= 16'd0;
                    phase <= phase + 1'b1;
                end
            end

            // Main FSM
            case (state)
                IDLE: begin
                    sclk_reg   <= 1'b1;
                    sda_out    <= 1'b1;
                    sda_out_en <= 1'b1; // Drive high idle state
                    if (iSTART && !config_done) begin
                        state <= START;
                        timer <= 16'd0;
                        phase <= 2'd0;
                    end
                end
                
                START: begin
                    // I2C Start condition: SDA goes low while SCLK is high
                    if (phase == 2'd0) begin
                        sda_out  <= 1'b0; 
                        sclk_reg <= 1'b1;
                    end 
                    else if (phase == 2'd2) begin
                        sclk_reg <= 1'b0; // Prepare for data phase
                    end 
                    else if (phase == 2'd3) begin
                        state     <= WRITE_DEVICE_ADDR;
                        shift_reg <= CAMERA_WRITE_ADDR;
                        bit_count <= 4'd0;
                        phase     <= 2'd0; // Reset phase for next state
                    end
                end
                
                WRITE_DEVICE_ADDR, WRITE_REG_ADDR, WRITE_DATA: begin
                    if (phase == 2'd0) begin
                        // Phase 0: SCLK low, change data
                        sclk_reg <= 1'b0;
                        sda_out  <= shift_reg[7]; // MSB first
                    end 
                    else if (phase == 2'd1) begin
                        // Phase 1: SCLK goes high
                        sclk_reg <= 1'b1;
                    end 
                    else if (phase == 2'd3) begin
                        // Phase 3: SCLK goes low, shift data
                        sclk_reg <= 1'b0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        
                        if (bit_count == 4'd7) begin
                            bit_count <= 4'd0;
                            phase     <= 2'd0;
                            // Determine next state
                            if (state == WRITE_DEVICE_ADDR) state <= ACK1;
                            else if (state == WRITE_REG_ADDR) state <= ACK2;
                            else state <= ACK3;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                ACK1, ACK2, ACK3: begin
                    if (phase == 2'd0) begin
                        sclk_reg   <= 1'b0;
                        sda_out_en <= 1'b0; // Release SDA (High-Z) for camera to drive
                    end 
                    else if (phase == 2'd1) begin
                        sclk_reg <= 1'b1; // Camera responds here (SDA should be 0)
                        // Note: A robust design would sample oSDA here to check for NACK
                    end 
                    else if (phase == 2'd3) begin
                        sclk_reg   <= 1'b0;
                        sda_out_en <= 1'b1; // Re-take control of SDA
                        phase      <= 2'd0;
                        
                        // Transition to next state
                        if (state == ACK1) begin
                            state     <= WRITE_REG_ADDR;
                            shift_reg <= lut_data[15:8]; // Load Register Address
                        end 
                        else if (state == ACK2) begin
                            state     <= WRITE_DATA;
                            shift_reg <= lut_data[7:0];  // Load Configuration Data
                        end 
                        else begin
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    // I2C Stop condition: SDA goes high while SCLK is high
                    if (phase == 2'd0) begin
                        sclk_reg <= 1'b0;
                        sda_out  <= 1'b0; 
                    end 
                    else if (phase == 2'd1) begin
                        sclk_reg <= 1'b1; // SCLK high
                    end 
                    else if (phase == 2'd3) begin
                        sda_out <= 1'b1;  // SDA high
                        state   <= DELAY;
                    end
                end
                
                DELAY: begin
                    // Wait to allow camera to process command
                    if (delay_cnt < 20'd100_000) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end 
                    else begin
                        delay_cnt <= 20'd0;
                        if (lut_index < (LUT_SIZE - 1)) begin
                            lut_index <= lut_index + 1'b1;
                            state     <= START; // Loop back for next register
                            timer     <= 16'd0;
                            phase     <= 2'd0;
                        end 
                        else begin
                            state       <= DONE;
                            config_done <= 1'b1; // All commands sent
                        end
                    end
                end
                
                DONE: begin
                    // Stay here until reset
                    config_done <= 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule