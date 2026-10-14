module tb_weight;

    reg [4:0] layer_sel;
    reg [14:0] addr;
    wire signed [15:0] weight;

    weight_rom dut (
        .layer_sel(layer_sel),
        .addr(addr),
        .weight(weight)
    );

    initial begin
        $dumpfile("Weight_rom.vcd");
        $dumpvars(0, tb_weight);

        layer_sel = 0;
        addr = 0;

        #10;
        layer_sel = 5'd0;
        addr = 15'd0;
        #10;
        $display("Conv1 weight[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd0;
        addr = 15'd111;
        #10;
        $display("Conv1 weight[111] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd1;
        addr = 15'd0;
        #10;
        $display("Conv1 bias[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd6;
        addr = 15'd0;
        #10;
        $display("Conv2 weight[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd7;
        addr = 15'd0;
        #10;
        $display("Conv2 bias[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd12;
        addr = 15'd0;
        #10;
        $display("Conv3 weight[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd18;
        addr = 15'd0;
        #10;
        $display("LSTM kernel[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd21;
        addr = 15'd0;
        #10;
        $display("Dense1 weight[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd23;
        addr = 15'd0;
        #10;
        $display("Output weight[0] = %h (%0d)", weight, $signed(weight));

        layer_sel = 5'd0;
        addr = 15'd112;
        #10;
        $display("Invalid Conv1 address = %h (expected 0000)", weight);

        layer_sel = 5'd31;
        addr = 15'd0;
        #10;
        $display("Invalid selector = %h (expected 0000)", weight);

        $finish;
    end

endmodule
