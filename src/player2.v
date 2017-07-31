// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "player1.v"

module player2(
    // input
    clock,
    user_input,
    next_input,
    p1_value,

    // output
    read,
    complete,
    correct,
    q
    );

    input clock;            // clock
    input user_input;       // data in from user
    input next_input;       // address of player2
    input [9:0] p1_value;   // player1's value

    output complete;        // whether player2 cracked player1's code or not.
    output reg read;
    output [9:0] q;         // player2's value
    output [1:0] correct;   // indicate whether player2 input is correct ot not.

    /* player2's value */
    reg [9:0] p2_value;
    /* indicate whether dot or line */
    wire ld_dot, ld_line;

    /* player1 copy */
    reg [9:0] p1_copy;

    /*  */
    reg [1:0] user_result;

    /* finite states */
    localparam  MORSE_NONE  = 2'b00,    // binary indicating nothing
                MORSE_DOT   = 2'b01,    // binary indicating a morse dot
                MORSE_LINE  = 2'b11 ;   // binary indicating a morse line

    localparam  NEUTRAL     = 2'b00,    // neutral state where player2 is not inputting
                CORRECT     = 2'b01,    // player2's input is correct
                INCORRECT   = 2'b10 ;   // player2's input is incorrect

    /* module to take in input and convert to morse code */
    morse_decoder morse2(
        .clock(clock),
        .user_input(user_input),
        .resetn(1'b0),
        .ld_dot(ld_dot),
        .ld_line(ld_line)
        );

    /* loop to concatentate morse code coming in with
     * existing morse code */
    always @(posedge clock) begin
        user_result <= NEUTRAL;
        if (read) begin
            read <= 1'b0;
            p1_copy <= p1_value;
            p2_value <= 10'b0;
        end
        else if (next_input) begin
            read <= 1'b1;
        end
        /* morse code segment is empty */
        else if (p1_copy[9:8] == 2'b00) begin
            user_result <= CORRECT;
            p1_copy <= p1_copy[7:0] << 2;
        end
        /* player2's input is equivalent to a morse code dot */
        else if (ld_dot) begin
            /* concatenate player2's new input with prev inputs */
            p2_value <= { p2_value[7:0], MORSE_DOT };
            /* check if player1's input is the same,
             * if it is, set correct to 1
             */
            if (p1_copy[9:8] == MORSE_DOT) begin
                p1_copy <= p1_copy[7:0] << 2;
                user_result <= CORRECT;
            end
            else begin
                user_result <= INCORRECT;
                p1_copy <= p1_value;
                p2_value <= 10'b0;
            end
        end
        /* player2's input is equivalent to a morse code line */
        else if (ld_line) begin
            /* concatenate player2's new input with prev inputs */
            p2_value <= { p2_value[7:0], MORSE_LINE };
            /* check if player1's input is the same,
             * if it is, set correct to 1
             */
            if (p1_copy[9:8] == MORSE_LINE) begin
                p1_copy <= p1_copy[7:0] << 2;
                user_result <= CORRECT;
            end
            else begin
                user_result <= INCORRECT;
                p1_copy <= p1_value;
                p2_value <= 10'b0;
            end
        end
    end
    assign correct = user_result;
    assign complete = clock ? (p2_value == p1_value) : 1'b0;
    assign q = p2_value;
endmodule

