module relu (
    input wire signed [15:0] x,
    output wire signed [15:0] y
);

assign y = x[15] ? 16'sd0 : x;

endmodule


module maxpool1d (
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    output wire signed [15:0] y
);

assign y = ($signed(a) >= $signed(b)) ? a : b;

endmodule
