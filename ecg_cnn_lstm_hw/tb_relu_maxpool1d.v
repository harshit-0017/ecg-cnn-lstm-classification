
`timescale 1ns / 1ps

module tb_relu_maxpool1d;

reg signed [15:0] x;
reg signed [15:0] a, b;

wire signed [15:0] relu_y;
wire signed [15:0] pool_y;

relu r1 (
    .x(x),
    .y(relu_y)
);

maxpool1d p1 (
    .a(a),
    .b(b),
    .y(pool_y)
);

initial begin
    $dumpfile("relu_maxpool1d.vcd");
    $dumpvars(0, tb_relu_maxpool1d);

    x = -253;
    a = 0;
    b = 120;
    #10;
    $display("ReLU Input=%0d Output=%0d", x, relu_y);
    $display("MaxPool A=%0d B=%0d Output=%0d", a, b, pool_y);

    x = 150;
    a = 250;
    b = 100;
    #10;
    $display("ReLU Input=%0d Output=%0d", x, relu_y);
    $display("MaxPool A=%0d B=%0d Output=%0d", a, b, pool_y);

    x = 0;
    a = -50;
    b = -20;
    #10;
    $display("ReLU Input=%0d Output=%0d", x, relu_y);
    $display("MaxPool A=%0d B=%0d Output=%0d", a, b, pool_y);

    $finish;
end

endmodule
