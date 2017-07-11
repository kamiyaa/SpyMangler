// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "player2.v"
`include "rate_divider.v"
`include "tumbler_vga.v"
`include "ram32x20.v"

module main(
    /* clock input */
    CLOCK_50,

    /* inputs */
    KEY,
    SW,

    /* PS/2 inputs */
    PS2_CLK,
    PS2_DAT,

    /* board outputs */
    LEDR,
    LEDG,
    HEX0,

    /* VGA outputs */
    VGA_CLK,       //    VGA Clock
    VGA_HS,        //    VGA H_SYNC
    VGA_VS,        //    VGA V_SYNC
    VGA_BLANK_N,   //    VGA BLANK
    VGA_SYNC_N,    //    VGA SYNC
    VGA_R,         //    VGA Red[9:0]
    VGA_G,         //    VGA Green[9:0]
    VGA_B          //    VGA Blue[9:0]
    );

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;         //    VGA Clock
    output          VGA_HS;          //    VGA H_SYNC
    output          VGA_VS;          //    VGA V_SYNC
    output          VGA_BLANK_N;     //    VGA BLANK
    output          VGA_SYNC_N;      //    VGA SYNC
    output  [9:0]   VGA_R;           //    VGA Red[9:0]
    output  [9:0]   VGA_G;           //    VGA Green[9:0]
    output  [9:0]   VGA_B;           //    VGA Blue[9:0]

    input           CLOCK_50;
    input   [3:0]   KEY;
    input   [17:0]  SW;

    output  [17:0]  LEDR;
    output  [7:0]   LEDG;
	output  [6:0]   HEX0;

    input           PS2_CLK;
    input           PS2_DAT;

    /* value for getting 1 hz using CLOCK_50 */
    wire [27:0] ONEHZ = 28'b0010111110101111000010000000;

    /* input maps */
    wire user_input = KEY[0];
    wire next_input = KEY[1];
    wire done_input = KEY[2];
    wire resetn	    = KEY[3];

    /* make a 1Hz clock */
    wire clock;
    rate_divider rate0(
        .clock_in(CLOCK_50),
        .clock_out(clock),
        .rate(ONEHZ)
        );

    /* finite states */
    localparam  S_START     = 5'd0,
                S_P1TURN    = 5'd1,
                S_P2TURN    = 5'd2,
                S_RESULT    = 5'd3 ;

    /* finite state machine logic */
    reg [3:0] current_state, next_state;
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed     pressed */
            S_START:    next_state = user_input ? S_START     :   S_P1TURN;
            S_P1TURN:   next_state = done_input ? S_P1TURN    :   S_P2TURN;
            S_P2TURN:   next_state = done_input ? S_P2TURN    :   S_RESULT;
            default:    next_state = S_START;
        endcase
    end

    reg p1_clock, p2_clock;
    /* datapath control */
    always @(*) begin: enable_signals
        // By default make all our signals 0
        case (current_state)
            S_P1TURN: begin
                p1_clock <= clock;
                p2_clock <= 0;
            end
            S_P2TURN: begin
                p1_clock <= 0;
                p2_clock <= clock;
            end
        endcase
    end
	 
    /* visual on LEDG for user */
    reg [2:0] input_mem;
    assign LEDG[2:0] = input_mem;
    always @(posedge clock) begin
        if (user_input)
            input_mem <= 0;
        else if (input_mem == 3'b111)
            input_mem <= 1'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

    reg [4:0] p2_addr;
    wire p2_out;

    player2 player2_0(
        .clock(p2_clock),
        .user_input(user_input),
        .next_input(next_input),
        .done_input(done_input),
        .resetn(resetn),
        .player1_value(p1_value),
        .correct(LEDG[7]),
        .q(p2_out)
        );

    always @(posedge clock) begin
        if (!p2_addr)
            p2_addr <= 4'b1111;
        if (next_input) begin
            if (p1_clock)
                p1_addr <= p1_addr + 1'b1;
            if (p2_clock)
                p2_addr <= p2_addr + 1'b1;
        end
    end

    /* shows current state, for DEBUGGING */
    hex_decoder hex0(
        .hex_digit(current_state),
        .segments(HEX0)
        );

    /* current_state registers */
    always@(posedge clock) begin: state_FFs
        if (!resetn)
            current_state <= S_START;
        else
            current_state <= next_state;
    end
endmodule
   
