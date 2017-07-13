// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "morse_decoder.v"

module player1(
    /* input */
    clock,          // clock from ps2
    user_input,     // data from ps2
    next_input,
    done_input,
    resetn          // reset current input
    );

    input       clock;
    input       user_input;
    input       next_input;
    input       done_input;
    input       resetn;

    reg [9:0] p1_value;

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
		      p1_value <= 0;
        // concatentate dot binary to player2's input value
        if (ld_dot)
            p1_value <= { p1_value, 2'b01 };
        // concatentate line binary to player2's input value
        if (ld_line)
            p1_value <= { p1_value, 2'b11 };
    end
endmodule
