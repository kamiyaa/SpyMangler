// Part 2 skeleton

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module tumbler_vga(
    CLOCK_50,    //    On Board 50 MHz

    // Your inputs and outputs here
    KEY,
    SW,
    // The ports below are for the VGA output.  Do not change.
    VGA_CLK,       //    VGA Clock
    VGA_HS,        //    VGA H_SYNC
    VGA_VS,        //    VGA V_SYNC
    VGA_BLANK_N,   //    VGA BLANK
    VGA_SYNC_N,    //    VGA SYNC
    VGA_R,         //    VGA Red[9:0]
    VGA_G,         //    VGA Green[9:0]
    VGA_B          //    VGA Blue[9:0]
    );

    input            CLOCK_50;                //    50 MHz
    input   [10:0]   SW;
    input   [3:0]   KEY;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output             VGA_CLK;                   //    VGA Clock
    output             VGA_HS;                    //    VGA H_SYNC
    output             VGA_VS;                    //    VGA V_SYNC
    output             VGA_BLANK_N;               //    VGA BLANK
    output             VGA_SYNC_N;                //    VGA SYNC
    output    [9:0]    VGA_R;                     //    VGA Red[9:0]
    output    [9:0]    VGA_G;                     //    VGA Green[9:0]
    output    [9:0]    VGA_B;                     //    VGA Blue[9:0]
    
    wire resetn;
    assign resetn = KEY[0];
    
    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
    wire writeEn;
    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(colour),
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
            .VGA_CLK(VGA_CLK)
            );

    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";
            
    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
    wire [7:0] a,b;

    datapath d0(
        .set_x(KEY[3]),
        .in(SW[6:0]),
        .reset(resetn),
        .x(a),
        .y(b)
        );

    // Instansiate FSM control
    control c0(
       .clock(CLOCK_50),
       .go(KEY[1]),
       .in_x(a),
       .in_y(b),
       .in_c(SW[9:7]),
       .full(SW[10]),
       .reset(resetn), 
       .x(x),
       .y(y),
       .c(colour),
       .print(writeEn)
       );

    endmodule


// controls the coordinates of the squares. Modify this to suite your needor delete it
module datapath(set_x, in, reset, x, y);
    input set_x, reset;
    input [6:0] in;
    output reg [7:0] x, y;
    always @(*)
    begin
        if (reset == 1'b0)
            begin
                x <= 8'b0;
                y <= 8'b0;
            end
        else if (set_x == 1'b0)
            x <= {1'b0,in};
        else
            y <= {1'b0,in};
    end
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
    always @(posedge clock)
    begin
        if (reset == 1'b0) // reset to clear screen
            begin
                // prepare to reset by declaring r for reset to be true, print to true and offset true
                r <= 1'b1;
                print <= 1'b1;
                offset <= 4'b0000;
            end
        else if (black == 16'b1111111111111111) // reset "reset"
            begin
                print <= 1'b0;
                black <= 16'b0;
                r = 1'b0;
            end
        else if (r == 1'b1)
            begin
                c <= 3'b0;
                black <= black + 1'b1;
            end
        else if (start == 1'b1 && go == 1'b1) // print begins when the start signal is given and unpressed
            begin
                start <= 1'b0;
                print <= 1'b1;
            end
        else if (go == 1'b0)// print by declaring start
            begin
                clcol = 1'b1;
                start <= 1'b1;
            end
        else if (offset == 4'b1111) // reset offset prints
            begin
                offset <= 4'b0000;
                print <= 1'b0;
            end
        else if (print == 1'b1 && r == 1'b0) // coordinates the next location to draw
            if (clcol == 1'b1) // clear the column
                begin
                    c <= 3'b0;
                    if (col == 10'b1111111111)// draw black along the column
                        begin
                            clcol = 1'b0;
                            col = 10'b0;
                            c <= in_c;
                        end
                    else
                        col <= col +1'b1;
                end
            else // draw our box
                begin
                // if box is filled in or not
                    if (offset == 4'b0101 | offset == 4'b0100 | offset == 4'b1000 | offset == 4'b1001)
                        begin
                            if (full == 1'b0)
                            c <= 3'b0;
                        end
                    else
                    // provide colour
                        c <= in_c;
                    offset <= offset + 4'b1;
                end
    end
    always @(*)
    begin
        if (r == 1'b1)
            begin
                x <= black[15:8];
                y <= black[7:0];
            end
        else
            begin
                
                if (clcol == 1'b1)
                    begin
                        x <= in_x+col[1:0];
                        y <= col[9:3];
                    end
                else
                    begin
                        x <= in_x+offset[3:2];
                        y <= in_y+offset[1:0];
                    end
            end
    end
endmodule
