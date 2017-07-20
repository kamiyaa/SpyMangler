// `timescale time_unit/time_precision
`timescale 1ns / 1ns

module morse_decoder(
    // Inputs
    clock,
    user_input,
    resetn,

    // Outputs
    ld_dot,
    ld_line
    );

    input clock;      // clock
    input user_input; // user input
    input resetn;     // reset button

    /* indicate whether a dot or line was detected */
    output ld_dot, ld_line;

    reg morse_dot, morse_line;

    /* registers to hold the current state and next state */
    reg [3:0] current_state, next_state;

    /* finite states */
    localparam  S_F1    = 4'd0,
                S_F2    = 4'd1,
                S_F3    = 4'd2,
                S_F4    = 4'd3,
                S_DOT   = 4'd4,
                S_LINE  = 4'd5 ;

    /* finite state machine logic */
    always @(*) begin: state_table
        case (current_state)
            /*                                    not pressed   pressed */
            S_F1:       next_state = user_input ? S_F1    :     S_F2;
            S_F2:       next_state = user_input ? S_DOT   :     S_F3;
            S_F3:       next_state = user_input ? S_F1    :     S_F4;
            S_F4:       next_state = user_input ? S_LINE  :     S_F2;
            S_DOT:      next_state = user_input ? S_F1    :     S_F2;
            S_LINE:     next_state = user_input ? S_F1    :     S_F2;
            default:    next_state = S_F1;
        endcase
    end

    /* datapath control */
    always @(*) begin: enable_signals
        case (current_state)
            /* set ld_dot to 1 when we've detected a dot */
            S_DOT: begin
                morse_dot = 1'b1;
            end
            /* set ld_line to 1 when we've detected a line */
            S_LINE: begin
                morse_line = 1'b1;
            end
            default: begin
                /* By default make all our signals 0 */
                morse_dot = 1'b0;
                morse_line = 1'b0;
            end
        endcase
    end

    /* current_state registers */
    always@(posedge clock) begin: state_FFs
        /* if reset is pressed, current_state will become S_F1 */
        if (!resetn)
            current_state <= S_F1;
        /* otherwise, current_state goes to next_state */
        else
            current_state <= next_state;
    end

    assign ld_dot = morse_dot;
    assign ld_line = morse_line;
endmodule
