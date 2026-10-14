`timescale 1ns / 1ps

module tb_conv1d_mac;

    reg clk = 0, rst = 1, start = 0;
    reg [3:0] out_ch = 0;
    reg signed [15:0] x0, x1, x2, x3, x4, x5, x6;
    wire signed [15:0] y;
    wire done;

    conv1d_mac dut (
        .clk(clk), .rst(rst), .start(start), .out_ch(out_ch),
        .x0(x0), .x1(x1), .x2(x2), .x3(x3),
        .x4(x4), .x5(x5), .x6(x6),
        .y(y), .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("conv1d_mac.vcd");
        $dumpvars(0, tb_conv1d_mac);

        x0 = 256; x1 = 256; x2 = 256; x3 = 256;
        x4 = 256; x5 = 256; x6 = 256;

        #20 rst = 0;

        #10 start = 1;
        #10 start = 0;
        wait(done);
        $display("Test 1: Channel=%0d, Output=%0d, Hex=%h", out_ch, $signed(y), y);

        #20;
        out_ch = 1;
        x0 = 128; x1 = 128; x2 = 128; x3 = 128;
        x4 = 128; x5 = 128; x6 = 128;

        start = 1;
        #10 start = 0;
        wait(done);
        $display("Test 2: Channel=%0d, Output=%0d, Hex=%h", out_ch, $signed(y), y);

        #20 $finish;
    end

endmodule