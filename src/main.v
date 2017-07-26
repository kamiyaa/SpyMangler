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
    output  [17:0]  LEDR;
    output  [7:0]   LEDG;
    output  [6:0]   HEX0, HEX2, HEX3, HEX4;


    /* Constants */
    localparam  ONE_HZ = 28'd50000000,
                TWO_HZ = 28'd25000000;

    /* input maps */
    wire user_input = KEY[0];
    wire next_input = KEY[1];
    wire done_input = KEY[2];
    wire resetn     = KEY[3];
    wire clock      = CLOCK_50;

    /* 2Hz clock using a rate divider */
    wire clock_2hz;
    rate_divider rate0(
        .clock_in(clock),
        .clock_out(clock_2hz),
        .rate(TWO_HZ)
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
    always @(posedge clock_2hz) begin
        /* no user input */
        if (user_input)
            input_mem <= 3'b0;
        /* maxed morse code */
        else if (input_mem == 3'b111)
            input_mem <= 3'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

    /* wires indicating turns */
    wire player1_turn   = (current_state == S_P1TURN);
    wire game_over      = (current_state == S_RESULT);

    /* clocks for player1 and player2 module that controls when they are active */
    wire p1_clock       = player1_turn ? clock_2hz : 1'b0;
    wire p2_clock       = (current_state == S_P2TURN) ? clock_2hz : 1'b0;

    /* current memory address player1 is writing to */
    reg [3:0]   p1_addr;
    /* current memory address player2 is reading from */
    reg [3:0]   p2_addr;
    /* current address pointer of ram for the game */
    wire [3:0]  ram_addr = player1_turn ? p1_addr : p2_addr;

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

    reg ram_clock;  // clock signal for ram to read/write from/to ram
    reg rwen;       // read/write ram parameter, 0 = read, 1 = write

    wire [9:0]  p1_value;           // input value by player1
    reg [9:0]   player1_value;      // reg to hold player1's input
    wire [9:0]  p1_value_out;       // player1's value out from ram
    wire [9:0]  p2_value;           // input value of player2
    reg [9:0]   p2_compare_value;   // value player2 must compare with

    reg p1_reset_n; // reset for player1
    reg p2_reset_n; // reset for player2

    /* control player1 and player2's memory pointer position */
    /* control current memory address pointer of game */
    always @(posedge ~next_input) begin
        rwen <= 0;
        ram_clock <= 0;
        p1_reset_n <= 0;
        p2_reset_n <= 0;
        case (current_state)
            /* store player1's input into register,
             * increment player1's ram pointer to new space,
             * enable writing to ram and finally start the ram clock
             */
            S_P1TURN: begin
                player1_value <= p1_value;
                p1_addr <= p1_addr + 1'b1;
                rwen <= 1;
                ram_clock <= 1;
                p1_reset_n <= 1;
            end
            /* increment player2's ram pointer to new space,
             * start the ram clock to receive a value and
             * store it in a register
             */
            S_P2TURN: begin
                p2_addr <= p2_addr + 1'b1;
                ram_clock <= 1;
                p2_compare_value <= p1_value_out;
                p2_reset_n <= 1;
            end
            /* reset the ram pointer of both players */
            default: begin
                p1_addr <= 1'b0;
                p2_addr <= 1'b0;
            end
        endcase
    end

    player1 player1_0(
        .clock(p1_clock),
        .user_input(user_input),
        .next_input(next_input),
        .done_input(done_input),
        .resetn(p1_reset_n),
        .q(p1_value)
        );

    ram32x10 ram0(
        .address(ram_addr),
        .clock(ram_clock),
        .data(player1_value),
        .wren(rwen),
        .q(p1_value_out)
        );

    wire [1:0] p2_correct;  // indicate whether player2's value is correct,
                            // 01 = correct, 10 = incorrect, 00 = no input
    wire p2_complete;       // indicate whether player2 has cracked
                            // player1's current morse code

    player2 player2_0(
        .clock(p2_clock),
        .user_input(user_input),
        .next_input(next_input),
        .done_input(done_input),
        .resetn(p2_reset_n),
        .p1_value(p2_compare_value),
        .correct(p2_correct),
        .q(p2_value)
        );

    /* signal from player2 to draw to vga */
    wire abcd_kyle_signal = (p2_correct != 2'b00);
    assign LEDG[7] = p2_complete;
    assign LEDG[6:5] = p2_correct;
    assign LEDG[4] = abcd_kyle_signal;

    /* output to LEDR of cumulative user input */
    reg [9:0] ledr_value;
    assign LEDR[9:0] = ledr_value;
    always @(*) begin
        case (current_state)
            S_P1TURN:   ledr_value <= p1_value;
            S_P2TURN:   ledr_value <= p1_value_out;
            default:    ledr_value <= 10'b1111_1111_11;
        endcase
    end

    /* current_state registers */
    always @(posedge clock_2hz) begin: state_FFs
        current_state <= next_state;
    end

    /* ------------ VGA ------------ */
    reg vga_correct_hold;
    always @(posedge abcd_kyle_signal) begin
        vga_correct_hold <= p2_correct[0];
    end

    wire [7:0] x,y;
    wire [2:0] colour;
    wire draw_full_box;

    translator trans0(
        .correct(vga_correct_hold), // 1bit, 1 if user input matches, 0 otherwise
        .signal(abcd_kyle_signal),  // signal to refresh/redraw... Automatically moves to next
        .columns(p1_addr),          // 6bit, binary of number of columns in code
        .selection(p2_value[1:0]),  // 2bit, 00 for emtpy, 01 for dot, 11 for slash
        .X(x),
        .Y(y),
        .colour(colour),
        .draw_full(draw_full_box),
        .reset(~game_over)
        );

    rate_divider rate2(
        // input
        .clock_in(CLOCK_50),
        .rate(28'b00011_00101_10111_00110_110),
    
        // output
        .clock_out(refresh)
        );
    
    reg h;
    always @(posedge refresh) begin
        if (h)
            h <= 1'b0;
        else
            h <= 1'b1;
    end

    tumbler_vga tummy0(
        .clock(CLOCK_50),
        .colour_in(colour),
        .draw_full(draw_full_box),
        .draw(h),
        .x_in(x),
        .y_in(y),
        .resetn(~game_over),
        .VGA_CLK(VGA_CLK),          //  VGA Clock
        .VGA_HS(VGA_HS),            //  VGA H_SYNC
        .VGA_VS(VGA_VS),            //  VGA V_SYNC
        .VGA_BLANK_N(VGA_BLANK_N),  //  VGA BLANK
        .VGA_SYNC_N(VGA_SYNC_N),    //  VGA SYNC
        .VGA_R(VGA_R),              //  VGA Red[9:0]
        .VGA_G(VGA_G),              //  VGA Green[9:0]
        .VGA_B(VGA_B)
        );
        defparam tummy0.BACKGROUND_IMAGE = "../res/spybackground.mif";
    
endmodule

