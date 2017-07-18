// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "player1.v"

module player2(
    // input
    clock,      // clock
    user_input, // data in from user
    next_input, // indicate next input
    done_input, // indicate user is done with input
    resetn,     // reset current input
    p1_value,   // player1's value

    // output
    complete,
    correct,
    q
    );

    input clock;
    input user_input;
    input next_input;
    input done_input;
    input resetn;
    input [9:0] p1_value;

    output reg correct;
    output complete;
    output [9:0] q;

    /* states */
    reg [3:0] current_state, next_state;
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
        correct <= 0;
        // morse value is empty
        if (curr_morse == 2'b00) begin
            correct <= 1;
            p1_copy <= p1_copy << 2;
        end
        // concatentate dot binary to player2's input value
        if (ld_dot) begin
            p2_value <= { p2_value, MORSE_DOT };
            if (curr_morse == MORSE_DOT) begin
                correct <= 1;
            end
            p1_copy <= p1_copy << 2;
        end
        // concatentate line binary to player2's input value
        if (ld_line) begin
            p2_value <= { p2_value, MORSE_LINE };
            if (curr_morse == MORSE_DOT) begin
                correct <= 1;
            end
            p1_copy <= p1_copy << 2;
        end
        // reset player2 value if incorrect
	    if (!correct) begin
            p1_copy <= p1_value;
            p2_value <= 0;
        end
    end
    assign complete = (p2_value == p1_value);
    assign q = p2_value;
endmodule
