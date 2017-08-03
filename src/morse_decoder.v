// `timescale time_unit/time_precision
`timescale 1ns / 1ns

/* morse decoder module */
/* This module is what controls the LEDG0-3 lights that indicate
if player 1 is going to input a line, dot, or nothing based on how
long KEY0 is held. Outputs if player inputted a line or dot or nothing
and gives that data to player1.v for it to concatentate values.  */
module morse_decoder(
    // Inputs
    clock,
    user_input,
    resetn,

    // Outputs
    ld_dot,
    ld_line
    );

    /* finite state diagram
        [1] = input is on
        [0] = input is off


                     +------<--------<-------<----+
                     |                            |
          +-----<----|---<-----+                  |
          |          |         |                  |
          V   [1]    V  [1]    |  [1]      [1]    |
        S_WAIT ---> S_F1 ---> S_F2 ---> S_F3 --->-+
        ^  ^        |  ^                 |
        |  |        |  |                 V
        |  |        |  +--<---+         S_LINE ->-+
        |  |        |         |         [1] |     |
        |  |        V   [1]   |             |     |
        |  +--<--- S_DOT -->--+---<-----<---+     |
        |                                         |
        +-----<---------<--------<---------<------+
    */

    input clock;      // clock
    input user_input; // user input
    input resetn;     // reset button

    /* indicate whether a dot or line was detected */
    output ld_dot, ld_line;

    reg morse_dot, morse_line;

    /* registers to hold the current state and next state */
    reg [3:0] current_state, next_state;

    /* finite states */
    localparam  S_WAIT  = 4'd0,     // initial state
                S_F1    = 4'd1,     // input is on for 1 clock cycle
                S_F2    = 4'd2,     // input is on for 2 clock cycles
                S_F3    = 4'd3,     // input is on for 3 clock cycles
                S_DOT   = 4'd4,     // state for indicating a morse dot has been inputted.
                S_LINE  = 4'd5 ;    // state for indicating a morse line has been inputted.

    /* finite state machine logic */
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed   pressed */
            S_WAIT:     next_state = user_input ? S_WAIT    :   S_F1;
            S_F1:       next_state = user_input ? S_DOT     :   S_F2;
            S_F2:       next_state = user_input ? S_WAIT    :   S_F3;
            S_F3:       next_state = user_input ? S_LINE    :   S_F1;
            S_DOT:      next_state = user_input ? S_WAIT    :   S_F1;
            S_LINE:     next_state = user_input ? S_WAIT    :   S_F1;
            default:    next_state = S_WAIT;
        endcase
    end

    /* datapath control */
    always @(*) begin: enable_signals
        case (current_state)
            /* set ld_dot to 1 for 1 clock cycle when we've detected a dot */
            S_DOT: begin
                morse_dot <= 1'b1;
            end
            /* set ld_line to 1 for 1 clock cycle when we've detected a line */
            S_LINE: begin
                morse_line <= 1'b1;
            end
            default: begin
                /* By default make all our signals 0 */
                morse_dot <= 1'b0;
                morse_line <= 1'b0;
            end
        endcase
    end

    /* current_state registers */
    always@(posedge clock) begin: state_FFs
        /* if reset is pressed, current_state will become S_WAIT */
        if (resetn)
            current_state <= S_WAIT;
        /* otherwise, current_state goes to next_state */
        else
            current_state <= next_state;
    end

    assign ld_dot = morse_dot;
    assign ld_line = morse_line;
endmodule
