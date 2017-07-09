// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "../src/player2.v"
`include "../src/rate_divider.v"

module test_player2(
    CLOCK_50,
    KEY,
    LEDR,
    LEDG
    );

    input CLOCK_50;
    input [2:0] KEY;
    output [17:0] LEDR;
    output [7:0] LEDG;

    wire [27:0] one_hz = 28'b0010111110101111000010000000;

    reg [19:0] p1_value = 6'b101110;

    wire clock;
    rate_divider rate0(
        .clock_in(CLOCK_50),
        .clock_out(clock),
        .rate(one_hz)
        );

    player2 player2_0(
        .clock(clock),
        .value_input(KEY[0]),
        .finish_input(KEY[2]),
        .resetn(KEY[1]),
        .player1_value(p1_value),
        .correct(LEDG[7]),
        .q(LEDR)
        );
		  
    // visual on LEDG
    reg [2:0] input_mem;
    assign LEDG[2:0] = input_mem;

    always @(posedge clock) begin
        if (KEY[0])
            input_mem <= 0;
        else if (input_mem == 3'b111)
            input_mem <= 1'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

endmodule
