`include "../src/input_module.v"
`include "../src/rate_divider.v"

module test_input_module(
    CLOCK_50,
    KEY,
    LEDR,
    LEDG);

    input CLOCK_50;
    input [1:0] KEY;
    output [2:0] LEDR;
    output [3:0] LEDG;

    wire [27:0] one_hz = 28'b0010111110101111000010000000;

    wire clock;
    rate_divider rate0(
        .clock_in(CLOCK_50),
        .clock_out(clock),
        .rate(one_hz)
        );

    reg [6:0] input_mem;
    assign LEDG = input_mem;

    input_module input0(
        .clock(clock),
        .input_in(KEY[0]),
        .resetn(1'b1),
        .ld_dot(LEDR[0]),
        .ld_line(LEDR[1])
        );

    always @(posedge clock) begin
        if (KEY[0])
            input_mem <= 0;
        else
            input_mem <= { input_mem[3:0], 1'b1 };
    end

endmodule
