// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "../src/ps2_keyboard.v"
`include "../src/hex_decoder.v"

module test_ps2_keyboard(
    /* PS/2 inputs */
    PS2_CLK,
    PS2_DAT,

    HEX0,
    HEX1
    );
    input PS2_CLK;
    input PS2_DAT;

    output [6:0] HEX0, HEX1;

    wire [7:0] data_out;
    wire data_complete;

    reg [3:0] hex0_val, hex1_val;

    ps2_keyboard keyboard_input(
        .ps2_clock(PS2_CLK),
        .ps2_data(PS2_DAT),
        .data_out(data_out),
        .data_complete(data_complete)
        );

    hex_decoder hex0(
        .hex_digit(hex0_val),
        .segments(HEX0)
        );

    hex_decoder hex1(
        .hex_digit(hex1_val),
        .segments(HEX1)
        );

    always @(posedge data_complete) begin
        hex0_val = data_out[3:0];
        hex1_val = data_out[7:4];
    end
endmodule
