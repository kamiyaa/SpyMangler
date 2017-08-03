// Part 2 skeleton
`timescale 1ns / 1ns

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

/* tumbler_vga module */
/* this module contains everything that has to deal with
drawing pixels on the VGA display*/
module tumbler_vga(
    clock,      //  On Board 50 MHz
    // Your inputs and outputs here
    colour_in,
    draw_full,
    draw,
    x_in,
    y_in,
    resetn,
    // The ports below are for the VGA output. Do not change.
    VGA_CLK,        //  VGA Clock
    VGA_HS,         //  VGA H_SYNC
    VGA_VS,         //  VGA V_SYNC
    VGA_BLANK_N,    //  VGA BLANK
    VGA_SYNC_N,     //  VGA SYNC
    VGA_R,          //  VGA Red[9:0]
    VGA_G,          //  VGA Green[9:0]
    VGA_B           //  VGA Blue[9:0]
    );
    /* parameter passed in indicating the .mif file to load */
    parameter BACKGROUND_IMAGE = "../res/spybackground.mif";

    input clock;        //  50 MHz expected
    input [2:0] colour_in;
    input [7:0] x_in, y_in;
    input draw_full, draw, resetn;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output            VGA_CLK;      //  VGA Clock
    output            VGA_HS;       //  VGA H_SYNC
    output            VGA_VS;       //  VGA V_SYNC
    output            VGA_BLANK_N;  //  VGA BLANK
    output            VGA_SYNC_N;   //  VGA SYNC
    output    [9:0]    VGA_R;       //  VGA Red[9:0]
    output    [9:0]    VGA_G;       //  VGA Green[9:0]
    output    [9:0]    VGA_B;       //  VGA Blue[9:0]

    /* Create the colour, x, y and
     * writeEn wires that are inputs to the controller. */
    wire [2:0] colour2;
    wire [7:0] x;
    wire [6:0] y;
    wire writeEn;
    /* Create an Instance of a VGA controller - there can be only one!
     * Define the number of colours as well as the initial background
     * image file (.MIF) for the controller. */
    vga_adapter VGA(
            .resetn(resetn),
            .clock(clock),
            .colour(colour2),
            .x(x),
            .y(y),
            .plot(writeEn),
            /* Signals for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = BACKGROUND_IMAGE;

    wire draw, draw_full;

    // Instansiate FSM control
    control c0(
        .clock(clock),
        .go(draw),
        .in_x(x_in),
        .in_y(y_in),
        .in_c(colour_in),
        .full(draw_full),
        .reset(resetn),
        .x(x),
        .y(y),
        .c(colour2),
        .print(writeEn)
        );

endmodule

// draws a square at coordinates given by in_x and in_y.
// if full given 1, the square is filled in
// colour is given as 3 bit RGB into in_c
// go triggers the drawing when it is released AFTER press (inverted so 0 is pressed down)
// x and y are fed to VGA along with print and c for colour
module control(clock, go, in_x, in_y, in_c, full, reset, x, y, c, print);
    input clock, go, reset, full;
    input [2:0] in_c;
    input [7:0] in_x, in_y;
    reg start = 1'b0;
    reg clcol = 1'b0;
    reg [9:0] col = 10'b0;
    reg [15:0] black = 16'b0;
    reg [3:0] offset = 4'b0000;
    reg r = 1'b0;
    output reg [2:0] c;
    output reg print = 1'b0;
    output reg [7:0] x, y;
    always @(posedge clock) begin
        // reset to clear screen
        if (reset == 1'b0) begin
            // prepare to reset by declaring r for reset to be true, print to true and offset true
            r <= 1'b1;
            print <= 1'b1;
            offset <= 4'b0000;
        end
        // reset "reset"
        else if (black == 16'b1111111111111111) begin
            print <= 1'b0;
            black <= 16'b0;
            r = 1'b0;
        end
        else if (r == 1'b1) begin
            c <= 3'b0;
            black <= black + 1'b1;
        end
        // print begins when the start signal is given and unpressed
        else if (start == 1'b1 && go == 1'b1) begin
            start <= 1'b0;
            print <= 1'b1;
        end
        // print by declaring start
        else if (go == 1'b0) begin
            clcol = 1'b1;
            start <= 1'b1;
        end
        // reset offset prints
        else if (offset == 4'b1111) begin
            offset <= 4'b0000;
            print <= 1'b0;
        end
        // coordinates the next location to draw
        else if (print == 1'b1 && r == 1'b0) begin
            // clear the column
            if (clcol == 1'b1) begin
                c <= 3'b0;
                // draw black along the column
                if (col == 10'b0101011011) begin
                    clcol = 1'b0;
                    col = 10'b0;
                    c <= in_c;
                end
                else
                    col <= col +1'b1;
            end
            // draw our box
            else begin
                // if box is filled in or not
                if (offset == 4'b0101 | offset == 4'b0100 | offset == 4'b1000 | offset == 4'b1001) begin
                    if (full == 1'b0)
                        c <= 3'b0;
                end
                // provide colour
                else
                    c <= in_c;
                offset <= offset + 4'b1;
            end
        end
    end
    // gets rid of "extra pixels"
    always @(*) begin
        // draws black over the x and y coordinates
        if (r == 1'b1) begin
            x <= black[15:8];
            y <= black[7:0];
        end
        else begin
          // shifts the extra pixels in column
            if (clcol == 1'b1) begin
                x <= in_x+col[1:0];
                y <= col[9:3] + 30;
            end
            // shifted x,y values to match background offset
            else begin
                x <= in_x+offset[3:2];
                y <= in_y+offset[1:0];
            end
        end
    end

endmodule
