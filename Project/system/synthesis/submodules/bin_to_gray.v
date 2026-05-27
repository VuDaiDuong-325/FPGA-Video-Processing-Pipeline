module bin_to_gray #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bin_i,
    output wire [WIDTH-1:0] gray_o
);

    assign gray_o = bin_i ^ (bin_i >> 1);

endmodule
