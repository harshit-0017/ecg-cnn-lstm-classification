module weight_rom (
    input wire [4:0] layer_sel,
    input wire [14:0] addr,
    output reg signed [15:0] weight
);

    reg [15:0] conv1_w [0:111];
    reg [15:0] conv1_b [0:15];

    reg [15:0] conv2_w [0:2559];
    reg [15:0] conv2_b [0:31];

    reg [15:0] conv3_w [0:6143];
    reg [15:0] conv3_b [0:63];

    reg [15:0] lstm_kernel [0:16383];
    reg [15:0] lstm_recurrent [0:16383];
    reg [15:0] lstm_bias [0:255];

    reg [15:0] dense1_w [0:2047];
    reg [15:0] dense1_b [0:31];

    reg [15:0] output_w [0:63];
    reg [15:0] output_b [0:1];

    initial begin
        $readmemh("hex_weights/layer1_conv1_param0.hex", conv1_w);
        $readmemh("hex_weights/layer1_conv1_param1.hex", conv1_b);

        $readmemh("hex_weights/layer4_conv2_param0.hex", conv2_w);
        $readmemh("hex_weights/layer4_conv2_param1.hex", conv2_b);

        $readmemh("hex_weights/layer8_conv3_param0.hex", conv3_w);
        $readmemh("hex_weights/layer8_conv3_param1.hex", conv3_b);

        $readmemh("hex_weights/layer12_lstm_param0.hex", lstm_kernel);
        $readmemh("weights/layer12_lstm_param1.hex", lstm_recurrent);
        $readmemh("weights/layer12_lstm_param2.hex", lstm_bias);

        $readmemh("hex_weights/layer14_dense1_param0.hex", dense1_w);
        $readmemh("weights/layer14_dense1_param1.hex", dense1_b);

        $readmemh("hex_weights/layer16_output_param0.hex", output_w);
        $readmemh("hex_weights/layer16_output_param1.hex", output_b);
    end

    always @* begin
        weight = 16'sd0;

        case (layer_sel)
            5'd0:  if (addr < 112)   weight = conv1_w[addr];
            5'd1:  if (addr < 16)    weight = conv1_b[addr];

            5'd6:  if (addr < 2560)  weight = conv2_w[addr];
            5'd7:  if (addr < 32)    weight = conv2_b[addr];

            5'd12: if (addr < 6144)  weight = conv3_w[addr];
            5'd13: if (addr < 64)    weight = conv3_b[addr];

            5'd18: if (addr < 16384) weight = lstm_kernel[addr];
            5'd19: if (addr < 16384) weight = lstm_recurrent[addr];
            5'd20: if (addr < 256)   weight = lstm_bias[addr];

            5'd21: if (addr < 2048)  weight = dense1_w[addr];
            5'd22: if (addr < 32)    weight = dense1_b[addr];

            5'd23: if (addr < 64)    weight = output_w[addr];
            5'd24: if (addr < 2)     weight = output_b[addr];

            default: weight = 16'sd0;
        endcase
    end

endmodule

// module weight_rom (
//     input wire [4:0] layer_sel,
//     input wire [14:0] addr,
//     output reg signed [15:0] weight
// );

//     reg [15:0] conv1_w [0:111];
//     reg [15:0] conv1_b [0:15];

//     reg [15:0] bn1_gamma [0:15];
//     reg [15:0] bn1_beta  [0:15];
//     reg [15:0] bn1_mean  [0:15];
//     reg [15:0] bn1_var   [0:15];

//     reg [15:0] conv2_w [0:2559];
//     reg [15:0] conv2_b [0:31];

//     reg [15:0] bn2_gamma [0:31];
//     reg [15:0] bn2_beta  [0:31];
//     reg [15:0] bn2_mean  [0:31];
//     reg [15:0] bn2_var   [0:31];

//     reg [15:0] conv3_w [0:6143];
//     reg [15:0] conv3_b [0:63];

//     reg [15:0] bn3_gamma [0:63];
//     reg [15:0] bn3_beta  [0:63];
//     reg [15:0] bn3_mean  [0:63];
//     reg [15:0] bn3_var   [0:63];

//     reg [15:0] lstm_kernel [0:16383];
//     reg [15:0] lstm_recurrent [0:16383];
//     reg [15:0] lstm_bias [0:255];

//     reg [15:0] dense1_w [0:2047];
//     reg [15:0] dense1_b [0:31];

//     reg [15:0] output_w [0:63];
//     reg [15:0] output_b [0:1];

//     initial begin
//         $readmemh("hex_weights/layer1_conv1_param0.hex", conv1_w);
//         $readmemh("hex_weights/layer1_conv1_param1.hex", conv1_b);

//         $readmemh("hex_weights/layer2_bn1_param0.hex", bn1_gamma);
//         $readmemh("hex_weights/layer2_bn1_param1.hex", bn1_beta);
//         $readmemh("hex_weights/layer2_bn1_param2.hex", bn1_mean);
//         $readmemh("hex_weights/layer2_bn1_param3.hex", bn1_var);

//         $readmemh("hex_weights/layer5_conv2_param0.hex", conv2_w);
//         $readmemh("hex_weights/layer5_conv2_param1.hex", conv2_b);

//         $readmemh("hex_weights/layer6_bn2_param0.hex", bn2_gamma);
//         $readmemh("hex_weights/layer6_bn2_param1.hex", bn2_beta);
//         $readmemh("hex_weights/layer6_bn2_param2.hex", bn2_mean);
//         $readmemh("hex_weights/layer6_bn2_param3.hex", bn2_var);

//         $readmemh("hex_weights/layer10_conv3_param0.hex", conv3_w);
//         $readmemh("hex_weights/layer10_conv3_param1.hex", conv3_b);

//         $readmemh("hex_weights/layer11_bn3_param0.hex", bn3_gamma);
//         $readmemh("hex_weights/layer11_bn3_param1.hex", bn3_beta);
//         $readmemh("hex_weights/layer11_bn3_param2.hex", bn3_mean);
//         $readmemh("hex_weights/layer11_bn3_param3.hex", bn3_var);

//         $readmemh("hex_weights/layer15_lstm_param0.hex", lstm_kernel);
//         $readmemh("hex_weights/layer15_lstm_param1.hex", lstm_recurrent);
//         $readmemh("hex_weights/layer15_lstm_param2.hex", lstm_bias);

//         $readmemh("hex_weights/layer17_dense1_param0.hex", dense1_w);
//         $readmemh("hex_weights/layer17_dense1_param1.hex", dense1_b);

//         $readmemh("hex_weights/layer19_output_param0.hex", output_w);
//         $readmemh("hex_weights/layer19_output_param1.hex", output_b);
//     end

//     always @* begin
//         weight = 16'sd0;

//         case (layer_sel)
//             0: if (addr < 112)   weight = conv1_w[addr];
//             1: if (addr < 16)    weight = conv1_b[addr];

//             2: if (addr < 16)    weight = bn1_gamma[addr];
//             3: if (addr < 16)    weight = bn1_beta[addr];
//             4: if (addr < 16)    weight = bn1_mean[addr];
//             5: if (addr < 16)    weight = bn1_var[addr];

//             6: if (addr < 2560)  weight = conv2_w[addr];
//             7: if (addr < 32)    weight = conv2_b[addr];

//             8: if (addr < 32)    weight = bn2_gamma[addr];
//             9: if (addr < 32)    weight = bn2_beta[addr];
//             10: if (addr < 32)   weight = bn2_mean[addr];
//             11: if (addr < 32)   weight = bn2_var[addr];

//             12: if (addr < 6144) weight = conv3_w[addr];
//             13: if (addr < 64)   weight = conv3_b[addr];

//             14: if (addr < 64)   weight = bn3_gamma[addr];
//             15: if (addr < 64)   weight = bn3_beta[addr];
//             16: if (addr < 64)   weight = bn3_mean[addr];
//             17: if (addr < 64)   weight = bn3_var[addr];

//             18: if (addr < 16384) weight = lstm_kernel[addr];
//             19: if (addr < 16384) weight = lstm_recurrent[addr];
//             20: if (addr < 256)   weight = lstm_bias[addr];

//             21: if (addr < 2048)  weight = dense1_w[addr];
//             22: if (addr < 32)    weight = dense1_b[addr];

//             23: if (addr < 64)    weight = output_w[addr];
//             24: if (addr < 2)     weight = output_b[addr];

//             default: weight = 16'sd0;
//         endcase
//     end

// endmodule
