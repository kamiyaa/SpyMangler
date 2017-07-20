// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "player1.v"

module player2(
    // input
    clock,
    user_input,
    next_input,
    done_input,
    resetn,
    p1_value,

    // output
    complete,
    correct,
    q
    );

    input clock;            // clock
    input user_input;       // data in from user
    input next_input;       // indicate next input
    input done_input;       // indicate user is done with input
    input resetn;           // reset current input
    input [9:0] p1_value;   // player1's value

    output complete;        // whether player2 cracked player1's code or not.
    output [9:0] q;         // player2's value
    output reg correct;     // 0 = incorrect input, 1 = correct input

    /* player2's value */
    reg [9:0] p2_value;
    /* indicate whether dot or line */
    wire ld_dot, ld_line;

    /* player1 copy */
    reg [9:0] p1_copy;

    /* finite states */
    localparam  MORSE_NONE  = 2'b00,
                MORSE_DOT   = 2'b01,
                MORSE_LINE  = 2'b11 ;

    /* module to take in input and convert to morse code */
    morse_decoder morse2(
        .clock(clock),
        .user_input(user_input),
        .resetn(resetn),
        .ld_dot(ld_dot),
        .ld_line(ld_line)
        );

    wire [1:0] curr_morse;
    assign curr_morse = p1_copy[9:8];

    /* loop to concatentate morse code coming in with
     * existing morse code */
    always @(posedge clock) begin
        correct <= 1'b0;

        /* morse code segment is empty */
        if (curr_morse == MORSE_NONE) begin
            correct <= 1'b1;
        end
        /* player2's input is equivalent to a morse code dot */
        else if (ld_dot) begin
            /* concatenate player2's new input with prev inputs */
            p2_value <= { p2_value[7:0], MORSE_DOT };
            /* check if player1's input is the same,
             * if it is, set correct to 1
             */
            if (curr_morse == MORSE_DOT)
                correct <= 1'b1;
        end
        /* player2's input is equivalent to a morse code line */
        else if (ld_line) begin
            /* concatenate player2's new input with prev inputs */
            p2_value <= { p2_value[7:0], MORSE_LINE };
            /* check if player1's input is the same,
             * if it is, set correct to 1
             */
            if (curr_morse == MORSE_LINE)
                correct <= 1'b1;
        end

        /* if player2 guessed the right code, left shift player1's code by 2 */
	    if (correct)
            p1_copy <= p1_copy << 2;
        /* otherwise, reload player1's value and reset player2's value */
        else begin
            p1_copy <= p1_value;
            p2_value <= 10'b0;
        end
    end
    assign complete = correct ? (p2_value == p1_value) : 1'b0;
    assign q = p2_value;
endmodule
