// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "player2.v"
`include "rate_divider.v"

module main(
    CLOCK_50,
    KEY,
    SW,
    LEDR,
    LEDG,
    HEX0
    );

    input CLOCK_50;
    input [3:0] KEY;
    input [17:0] SW;
    output [17:0] LEDR;
    output [7:0] LEDG;
	 output [6:0] HEX0;

    // value for getting 1 hz using CLOCK_50
    wire [27:0] one_hz = 28'b0010111110101111000010000000;

    wire input_in		= KEY[0];
    wire resetn		= KEY[1];
    wire done_input	= KEY[3];

    wire clock;
    rate_divider rate0(
        .clock_in(CLOCK_50),
        .clock_out(clock),
        .rate(one_hz)
        );
    reg [3:0] current_state, next_state;

    /* finite states */
    localparam  S_START     = 5'd0,
                S_P1TURN    = 5'd1,
                S_P2TURN    = 5'd2,
                S_RESULT    = 5'd3;

    // Next state logic aka our state table
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed     pressed */
            S_START:    next_state = input_in   ? S_START     :   S_P1TURN;
            S_P1TURN:   next_state = done_input ? S_P1TURN    :   S_P2TURN;
            S_P2TURN:   next_state = done_input ? S_P2TURN    :   S_RESULT;
            default:    next_state = S_START;
        endcase
    end     // state_table

    reg p1_clock, p2_clock;
    // Output logic aka all of our datapath control signals
    always @(*) begin: enable_signals
        // By default make all our signals 0
        case (current_state)
            S_P1TURN: begin
                p1_clock <= clock;
                p2_clock <= 0;
            end
            S_P2TURN: begin
                p1_clock <= 0;
                p2_clock <= clock;
            end
        endcase
    end    // enable_signals
	 
    // visual on LEDG
    reg [2:0] input_mem;
    assign LEDG[2:0] = input_mem;

    always @(posedge clock) begin
        if (input_in)
            input_mem <= 0;
        else if (input_mem == 3'b111)
            input_mem <= 1'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

    player2 player2_0(
        .clock(p2_clock),
        .value_input(input_in),
        .finish_input(done_input),
        .resetn(resetn),
        .player1_value(p1_value),
        .correct(LEDG[7]),
        .q(LEDR)
        );

    hex_decoder hex0(
        .hex_digit(current_state),
        .segments(HEX0)
        );

    // current_state registers
    always@(posedge clock) begin: state_FFs
        if (!resetn)
            current_state <= S_START;
        else
            current_state <= next_state;
    end // state_FFS
endmodule
   
