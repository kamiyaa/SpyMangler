// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "rate_divider.v"
`include "hex_decoder.v"
`include "player2.v"
`include "tumbler_vga.v"
`include "ram32x10.v"
`include "translator.v"

module tester(
    /* clock input */
    CLOCK_50,

    /* inputs */
    KEY,
    SW,

    /* board outputs */
    LEDR,
    LEDG,

    HEX0,
    HEX2,
    HEX3,
    HEX4,

    /* VGA outputs */
    VGA_CLK,        //    VGA Clock
    VGA_HS,         //    VGA H_SYNC
    VGA_VS,         //    VGA V_SYNC
    VGA_BLANK_N,    //    VGA BLANK
    VGA_SYNC_N,     //    VGA SYNC
    VGA_R,          //    VGA Red[9:0]
    VGA_G,          //    VGA Green[9:0]
    VGA_B           //    VGA Blue[9:0]
    );

    // Do not change the following outputs
    output          VGA_CLK;         //    VGA Clock
    output          VGA_HS;          //    VGA H_SYNC
    output          VGA_VS;          //    VGA V_SYNC
    output          VGA_BLANK_N;     //    VGA BLANK
    output          VGA_SYNC_N;      //    VGA SYNC
    output  [9:0]   VGA_R;           //    VGA Red[9:0]
    output  [9:0]   VGA_G;           //    VGA Green[9:0]
    output  [9:0]   VGA_B;           //    VGA Blue[9:0]

    /* inputs */
    input           CLOCK_50;
    input   [3:0]   KEY;
    input   [17:0]  SW;
    /* ouputs */
    output  [9:0]   LEDR;
    output  [7:0]   LEDG;
    output  [6:0]   HEX0, HEX2, HEX3, HEX4;


wire p2_correct, p2_signal, draw_full_box, refresh;
wire [5:0] p1_addr;
wire [1:0] p2_value;
wire [7:0] x, y ;
wire [2:0] colour;

assign p2_correct = SW[17];
assign p2_signal = KEY[2];
assign p1_addr = 6'b000100;
assign p2_value = SW[1:0];


    translator trans0(
        .correct(p2_correct),     // 1bit, 1 if user input matches, 0 otherwise
        .signal(p2_signal),      // signal to refresh/redraw... Automatically moves to next
        .columns(p1_addr),     // 6bit, binary of number of columns in code
        .selection(p2_value),   // 2bit, 00 for emtpy, 01 for dot, 11 for slash
        .X(x),
        .Y(y),
        .colour(colour),
        .draw_full(draw_full_box),
		  .reset(KEY[3])
        );

	 assign LEDR[2:0] = colour;
    rate_divider(
		// input
		.clock_in(CLOCK_50),
		.rate(28'b00011_00101_10111_00110_110),
	
		// output
		.clock_out(refresh));
	
	reg h; 
	always @(posedge refresh) begin
		if (h)
			h <= 1'b0;
		else
			h <= 1'b1;
	end
		assign LEDR[4] = h;
    tumbler_vga tummy0(
		.clock(CLOCK_50),
		.colour_in(colour),
		.draw_full(draw_full_box),
		.draw(h),
		.x_in(x),
		.y_in(y),
		.resetn(KEY[3]),
		.VGA_CLK(VGA_CLK),        //	VGA Clock
		.VGA_HS(VGA_HS),            //	VGA H_SYNC
		.VGA_VS(VGA_VS),            //	VGA V_SYNC
		.VGA_BLANK_N(VGA_BLANK_N),  //	VGA BLANK
		.VGA_SYNC_N(VGA_SYNC_N),    //	VGA SYNC
		.VGA_R(VGA_R),              //	VGA Red[9:0]
		.VGA_G(VGA_G),              //	VGA Green[9:0]
		.VGA_B(VGA_B)  
	);
    
endmodule
