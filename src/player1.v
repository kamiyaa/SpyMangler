// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "morse_decoder.v"

module player1(
    /* inputs */
    clock,
    user_input,     // user input data
    next_input,     // user input indicating next char
    done_input,     // user input indicating end of turn
    resetn,         // reset current input

    /* outputs */
    q
    );

    input clock;
    input user_input;
    input next_input;
    input done_input;
    input resetn;

    output [9:0] q;

    reg [9:0] p1_value;

    /* finite states */
    localparam  MORSE_DOT   = 2'b01,
                MORSE_LINE  = 2'b11 ;

    /* module to take in input and convert to morse code */
    morse_decoder morse1(
        .clock(clock),
        .user_input(user_input),
        .resetn(resetn),
        .ld_dot(ld_dot),
        .ld_line(ld_line)
        );

    /* loop to concatentate morse code coming in with
     * existing morse code */
    always @(posedge clock) begin
        // reset player2 value
	     if (!resetn)
            p1_value <= 0;
        // concatentate dot binary to player2's input value
        if (ld_dot)
            p1_value <= { p1_value, MORSE_DOT };
        // concatentate line binary to player2's input value
        if (ld_line)
            p1_value <= { p1_value, MORSE_LINE };
    end
    assign q = p1_value;
endmodule
