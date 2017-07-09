// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "input_module.v"

module player2(
    // input
    clock,
    value_input,
    finish_input,
    resetn,
    player1_value,

    // output
    correct,
    q
    );

    input clock;
    input finish_input;
    input value_input;
    input resetn;
    input [19:0] player1_value;

    output correct;
    output [19:0] q;

    reg [19:0] p1_value = 6'b101110;
    reg [19:0] player2_value;
    reg [3:0] current_state, next_state;

    wire ld_dot, ld_line;

    input_module morse_decoder(
        .clock(clock),
        .input_in(value_input),
        .resetn(resetn),
        .ld_dot(ld_dot),
        .ld_line(ld_line)
        );

    always @(posedge clock) begin
        // reset player2 value
	     if (!resetn)
		      player2_value <= 0;
        // concatentate dot binary to player2's input value
        if (ld_dot)
            player2_value <= { player2_value, 2'b10 };
        // concatentate line binary to player2's input value
        if (ld_line)
            player2_value <= { player2_value, 4'b1110 };
    end
    // assign correct a value when player click finish
    assign correct = finish_input ? 1'b0 : (player2_value == player1_value);
    assign q = player2_value;
endmodule
