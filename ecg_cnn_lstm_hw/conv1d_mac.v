module conv1d_mac (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [3:0] out_ch,
    input wire signed [15:0] x0, x1, x2, x3, x4, x5, x6,
    output reg signed [15:0] y,
    output reg done
);

    localparam IDLE = 2'd0;
    localparam MAC  = 2'd1;
    localparam BIAS = 2'd2;
    localparam FIN  = 2'd3;

    reg [1:0] state;
    reg [2:0] tap;
    reg [3:0] ch;

    reg signed [15:0] samples [0:6];
    reg signed [31:0] acc;
    reg signed [31:0] prod;
    reg signed [31:0] acc_next;
    reg signed [31:0] bias_ext;
    reg signed [31:0] result;

    wire [14:0] waddr;
    wire [4:0] layer_sel;
    wire signed [15:0] weight;

    assign layer_sel = (state == BIAS) ? 5'd1 : 5'd0;
    assign waddr = (state == BIAS) ? {11'd0, ch} : (tap * 16 + ch);

    weight_rom rom (
        .layer_sel(layer_sel),
        .addr(waddr),
        .weight(weight)
    );

    always @* begin
        case (tap)
            3'd0: prod = $signed(samples[0]) * $signed(weight);
            3'd1: prod = $signed(samples[1]) * $signed(weight);
            3'd2: prod = $signed(samples[2]) * $signed(weight);
            3'd3: prod = $signed(samples[3]) * $signed(weight);
            3'd4: prod = $signed(samples[4]) * $signed(weight);
            3'd5: prod = $signed(samples[5]) * $signed(weight);
            3'd6: prod = $signed(samples[6]) * $signed(weight);
            default: prod = 32'sd0;
        endcase

        acc_next = acc + prod;
        bias_ext = {{8{weight[15]}}, weight, 8'b0};
        result = (acc + bias_ext) >>> 8;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tap <= 0;
            ch <= 0;
            acc <= 0;
            y <= 0;
            done <= 0;

            samples[0] <= 0;
            samples[1] <= 0;
            samples[2] <= 0;
            samples[3] <= 0;
            samples[4] <= 0;
            samples[5] <= 0;
            samples[6] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        samples[0] <= x0;
                        samples[1] <= x1;
                        samples[2] <= x2;
                        samples[3] <= x3;
                        samples[4] <= x4;
                        samples[5] <= x5;
                        samples[6] <= x6;
                        ch <= out_ch;
                        tap <= 0;
                        acc <= 0;
                        state <= MAC;
                    end
                end

                MAC: begin
                    acc <= acc_next;
                    if (tap == 3'd6) begin
                        state <= BIAS;
                    end else begin
                        tap <= tap + 1'b1;
                    end
                end

                BIAS: begin
                    if (result > 32'sd32767)
                        y <= 16'sh7fff;
                    else if (result < -32'sd32768)
                        y <= 16'sh8000;
                    else
                        y <= result[15:0];

                    state <= FIN;
                end

                FIN: begin
                    done <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
