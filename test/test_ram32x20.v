// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "../src/player2.v"
`include "../src/rate_divider.v"
`include "../src/ram32x20.v"

module test_ram32x20(
    /* clock input */
    CLOCK_50,

    /* inputs */
    KEY,
    SW,
    LEDR,
    );

    input CLOCK_50;
    input [17:0] SW;
    input [2:0] KEY;

    output [17:0] LEDR;
    wire [3:0] data_out;

    reg [4:0] counter;
	
    ram32x20 ram0(
        .data(SW[16:0]),
        .address(counter),
        .wren(SW[17]),
        .clock(KEY[0]),
        .q(data_out)
        );

    always @(negedge KEY[0]) begin
        if (!KEY[1])
            counter <= 0;
        else
            counter <= counter + 1'b1;
    end
    assign LEDR = data_out;

endmodule
