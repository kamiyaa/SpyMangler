// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "morse_decoder.v"

module player2(
    // input
    clock,      // clock
    user_input, // data in from user
    next_input, // indicate next input
    done_input, // indicate user is done with input
    resetn,     // reset current input
    p1_value,

    // output
    correct,
    q
    );

    input clock;
    input user_input;
    input next_input;
    input done_input;
    input resetn;
    input [9:0] p1_value;

    output correct;
    output [9:0] q;

    reg [9:0] p2_value;
    reg [3:0] current_state, next_state;

    wire ld_dot, ld_line;

    /* module to take in input and convert to morse code */
    morse_decoder morse0(
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
		      p2_value <= 0;
        // concatentate dot binary to player2's input value
        if (ld_dot)
            p2_value <= { p2_value, 2'b01 };
        // concatentate line binary to player2's input value
        if (ld_line)
            p2_value <= { p2_value, 2'b11 };
    end
    // assign correct a value when player click finish
    assign correct = done_input ? 1'b0 : (p2_value == p1_value);
    assign q = p2_value;
endmodule
