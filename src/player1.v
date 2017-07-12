// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "ram32x8.v"
`include "ps2_keyboard.v"

module player1(
    /* input */
    ps2_clock,  // clock from ps2
    ps2_data,   // data from ps2
    resetn,     // reset current input

    /* output */
    mem_addr
    );

    input       ps2_clock;
    input       ps2_data;
    input       resetn;

    output reg [3:0] mem_addr;

    wire [7:0]  data_out;
    wire        data_complete;

    /* module to take in input and convert to morse code */
    ps2_keyboard keyboard_input(
        .ps2_clock(p2_clock),
        .ps2_data(ps2_data),
        .data_out(data_out),
        .data_complete(data_complete)
        );

    reg [3:0] mem_addr;
    wire [7:0] null;

    ram32x8 ram_storage(
        .address(mem_addr),
        .clock(data_complete),
        .data(data_out),
        .wren(data_complete),
        .q(null)
        );

    always @(negedge data_complete) begin
        if (!resetn)
            mem_addr <= 0;
        else
            mem_addr <= mem_addr + 1'b1;
    end
endmodule
