module synchronizer #(
    parameter WIDTH = 4
)(
    input  wire             clk_i,
    input  wire             rst_i,
    input  wire [WIDTH-1:0] d_in_i,
    output reg  [WIDTH-1:0] d_out_o
);

    reg [WIDTH-1:0] q1_r;

    always @(posedge clk_i) begin
        if (rst_i) begin
            q1_r    <= 0;
            d_out_o <= 0;
        end else begin
            q1_r    <= d_in_i;
            d_out_o <= q1_r;
        end
    end

endmodule
