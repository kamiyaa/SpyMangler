// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "morse_decoder.v"

module player1(
    /* inputs */
    clock,
    user_input,
    resetn,

    /* outputs */
    q,
    );

    input clock;            // clock
    input user_input;       // data in from user
    input resetn;           // reset current input

    output [9:0] q;         // player1's value

    reg [9:0] p1_value;

    /* indicate whether dot or line */
    wire ld_dot, ld_line;

    /* finite states */
    localparam  MORSE_NONE  = 2'b00,
                MORSE_DOT   = 2'b01,
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
        // reset player1 value
        if (resetn) begin
            p1_value <= 10'b0;
        end
        // concatentate dot binary to player2's input value
        else if (ld_dot) begin
            p1_value <= { p1_value[7:0], MORSE_DOT };
        end
        // concatentate line binary to player2's input value
        else if (ld_line) begin
            p1_value <= { p1_value[7:0], MORSE_LINE };
        end
    end
    assign q = p1_value;
endmodule
