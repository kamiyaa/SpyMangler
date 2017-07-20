// `timescale time_unit/time_precision
`timescale 1ns / 1ns

`include "../src/rate_divider.v"
`include "../src/hex_decoder.v"
`include "../src/player2.v"
`include "../src/ram32x10.v"

module test_ram_timing(
    CLOCK_50,
    KEY,
    LEDR,
    LEDG,
    HEX0,
    HEX2,
    HEX3

    );

    input CLOCK_50;
    input [3:0] KEY;
    output [17:0] LEDR;
    output [6:0] LEDG;
    output [6:0] HEX0, HEX2, HEX3;

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

    /* finite states */
    localparam  S_START     = 5'd0,
                S_P1TURN    = 5'd1,
                S_P2TURN    = 5'd2,
                S_RESULT    = 5'd3 ;

    /* finite state machine logic */
    reg [3:0] current_state, next_state;
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed   pressed */
            S_START:    next_state = done_input ? S_START   :   S_P1TURN;
            S_P1TURN:   next_state = done_input ? S_P1TURN  :   S_P2TURN;
            S_P2TURN:   next_state = done_input ? S_P2TURN  :   S_RESULT;
            default:    next_state = done_input ? S_RESULT  :   S_START;
        endcase
    end

    /* shows current state, for DEBUGGING */
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
            input_mem <= 0;
        /* maxed morse code */
        else if (input_mem == 3'b111)
            input_mem <= 1'b1;
        else
            input_mem <= { input_mem[1:0], 1'b1 };
    end

    /* data control */
    reg             p1_clock;   // clock for player 1
    reg             p2_clock;   // clock for player 2
    reg             rwen;       // 1 for write, 0 for read from ram
    reg             ram_clock;
    reg     [3:0]   ram_addr;   // current address pointer of ram for game
	 /* current memory address pointer of ram for player1 and player 2 */
    reg     [3:0]   p1_addr;
    reg     [3:0]   p2_addr;
	 
    /* datapath control */
    always @(*) begin: enable_signals
        // By default make all our signals 0
        case (current_state)
            S_START: begin
                p1_clock <= 0;
                p2_clock <= 0;
                ram_clock <= 1;
                rwen <= 0;
            end
            S_P1TURN: begin
                p1_clock <= clock_1hz;
                ram_clock <= ~next_input;
                rwen <= 1;
                p2_clock <= 0;
            end
            S_P2TURN: begin
                p1_clock <= 0;
                rwen <= 0;
                ram_clock <= ~next_input;
                p2_clock <= clock_1hz;
            end
            S_RESULT: begin
                p1_clock <= 0;
                p2_clock <= 0;
                rwen <= 0;
            end
        endcase
    end

    /* control player1 and player2's memory pointer position */
    /* control current memory address pointer of game */
    always @(posedge ram_clock) begin
        if (current_state == S_START) begin
            p1_addr <= 0;
            p2_addr <= 0;
        end
        if (current_state == S_P1TURN)
            p1_addr <= p1_addr + 1;
            ram_addr <= p1_addr;
        if (current_state == S_P2TURN)
            p2_addr <= p2_addr + 1;
            ram_addr <= p2_addr;
    end
	 
	hex_decoder hex2(
        .hex_digit(p1_addr),
        .segments(HEX2)
        );
	hex_decoder hex3(
        .hex_digit(p2_addr),
        .segments(HEX3)
        );

    wire    [9:0]   p1_value;       // input value of player1 to be stored in ram
    wire    [9:0]   p1_value_out;   // value out from ram

    wire p2_signal = (current_state == S_P2TURN && ~user_input);
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

    reg [9:0] ledr_value;

    always @(*) begin
        if (current_state == S_P1TURN)
            ledr_value <= p1_value;
        if (current_state == S_P2TURN)
            ledr_value <= p1_value_out;
    end

    assign LEDR = ledr_value;

    /* current_state registers */
    always@(posedge clock_1hz) begin: state_FFs
        if (!resetn)
            current_state <= S_START;
        else
            current_state <= next_state;
    end
endmodule
