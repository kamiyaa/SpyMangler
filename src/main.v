// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "rate_divider.v"
`include "hex_decoder.v"
`include "player2.v"
`include "tumbler_vga.v"
`include "ram32x10.v"
`include "translator.v"

module main(
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


    /* Constants */
    wire [27:0] ONE_HZ = 28'b0010111110101111000010000000;

    /* input maps */
    wire user_input = KEY[0];
    wire next_input = KEY[1];
    wire done_input = KEY[2];
    wire resetn     = KEY[3];
    wire clock      = CLOCK_50;

    /* 1Hz clock using a rate divider */
    wire clock_1hz;
    rate_divider rate0(
        .clock_in(clock),
        .clock_out(clock_1hz),
        .rate(ONE_HZ)
        );

    /* registers to hold the current state and next state */
    reg [3:0] current_state, next_state;

    /* finite states */
    localparam  S_START     = 4'd0,
                S_P1TURN    = 4'd1,
                S_P2TURN    = 4'd2,
                S_RESULT    = 4'd3 ;

    /* finite state machine logic */
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed   pressed */
            S_START:    next_state = done_input ? S_START   :   S_P1TURN;
            S_P1TURN:   next_state = done_input ? S_P1TURN  :   S_P2TURN;
            S_P2TURN:   next_state = done_input ? S_P2TURN  :   S_RESULT;
            default:    next_state = done_input ? S_RESULT  :   S_START;
        endcase
    end

    /* shows current state, for visuals */
    hex_decoder hex0(
        .hex_digit(current_state),
        .segments(HEX0)
        );

    /* morse code visual for user on LEDG */
    reg [2:0] input_mem;
    assign LEDG[2:0] = input_mem;
    always @(posedge clock_1hz) begin
        /* no user input */
        if (user_input)
            input_mem <= 3'b0;
        /* maxed morse code */
        else if (input_mem == 3'b111)
            input_mem <= 3'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

    /* data control */
    wire        p1_clock;   // clock for player1 module
    wire        p2_clock;   // clock for player2 module
    wire        rwen;       // read/write ram parameter, 0 = read, 1 = write
    reg         ram_clock;  // clock for ram to signal read/write from/to ram

    /* p1_clock and p2_clock are only active during their respective
     * machine states
     */
    assign p1_clock = (current_state == S_P1TURN) ? clock_1hz : 1'b0;
    assign p2_clock = (current_state == S_P2TURN) ? clock_1hz : 1'b0;
    /* enable write to ram only during player1's turn */
    assign rwen     = (current_state == S_P1TURN) ? 1'b1 : 1'b0;

    reg [3:0]   p1_addr;    // current memory address player1 is writing to
    reg [3:0]   p2_addr;    // current memory address player2 is reading from
    reg [3:0]   ram_addr;   // current address pointer of ram for the game

    /* visual for memory address of player1 and player2 */
	hex_decoder hex2(
        .hex_digit(p1_addr),
        .segments(HEX2)
        );
	hex_decoder hex3(
        .hex_digit(p2_addr),
        .segments(HEX3)
        );
    hex_decoder hex4(
        .hex_digit(ram_addr),
        .segments(HEX4)
        );
	 
    /* datapath control */
    always @(*) begin: enable_signals
        case (current_state)
            S_START: begin
                ram_clock <= 1'b1;
            end
            S_P1TURN: begin
                ram_clock <= ~next_input;
            end
            S_P2TURN: begin
                ram_clock <= ~next_input;
            end
            default: begin
                ram_clock <= 1'b0;
            end
        endcase
    end

    /* control player1 and player2's memory pointer position */
    /* control current memory address pointer of game */
    always @(posedge ram_clock) begin
        if (current_state == S_START) begin
            p1_addr <= 1'b0;
            p2_addr <= 1'b0;
            ram_addr <= 1'b0;
        end
        if (current_state == S_P1TURN)
            ram_addr <= p1_addr;
            p1_addr <= p1_addr + 1'b1;
        if (current_state == S_P2TURN)
            ram_addr <= p2_addr;
            p2_addr <= p2_addr + 1'b1;
    end

    wire    [9:0]   p1_value;       // input value of player1 to be stored in ram
    wire    [9:0]   p1_value_out;   // value out from ram
    wire    [1:0]   p2_value;       // input value of player2

    /* indicate whether player2's current input is correct
     * and whether the entirety of player2's morse code is correct
     */
    wire p2_correct, p2_complete;

    /* signal from player2 to draw to vga */
    wire p2_signal = (current_state == S_P2TURN && ~user_input);
    /* signal indicating the game is over */
    wire game_over = (current_state == S_RESULT);

    player1 player1_0(
        .clock(p1_clock),
        .user_input(user_input),
        .next_input(next_input),
        .done_input(done_input),
        .resetn(resetn),
        .q(p1_value)
        );

    ram32x10 ram0(
        .address(ram_addr),
        .clock(ram_clock),
        .data(p1_value),
        .wren(rwen),
        .q(p1_value_out)
        );

    player2 player2_0(
        .clock(p2_clock),
        .user_input(user_input),
        .next_input(next_input),
        .done_input(done_input),
        .resetn(resetn),
        .p1_value(p1_value_out),

        .correct(p2_correct),
        .complete(p2_complete),
        .q(p2_value)
        );

    /* current_state registers */
    always@(posedge clock_1hz) begin: state_FFs
        if (!resetn)
            current_state <= S_START;
        else
            current_state <= next_state;
    end

    wire [7:0] x,y;
    wire [2:0] colour;
    wire draw_full_box;
	 
	 assign LEDR[2] = p2_correct;
	 assign LEDR[3] = p2_signal;

    translator trans0(
        .correct(p2_correct),     // 1bit, 1 if user input matches, 0 otherwise
        .signal(p2_signal),      // signal to refresh/redraw... Automatically moves to next
        .columns(p1_addr),     // 6bit, binary of number of columns in code
        .selection(p2_value),   // 2bit, 00 for emtpy, 01 for dot, 11 for slash
        .X(x),
        .Y(y),
        .colour(colour),
        .draw_full(draw_full_box)
        );

    tumbler_vga tummy0(
		.clock(CLOCK_50),
		.colour_in(3'b111),
		.draw_full(draw_full_box),
		.draw(KEY[0]),
		.x_in(x),
		.y_in(y),
		.resetn(~game_over),
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

