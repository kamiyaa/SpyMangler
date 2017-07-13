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
    output reg ld_dot, ld_line;

    /* registers to hold the current state and next state */
    reg [3:0] current_state, next_state;

    /* finite states */
    localparam  S_F1    = 5'd0,
                S_F2    = 5'd1,
                S_F3    = 5'd2,
                S_F4    = 5'd3,
                S_DOT   = 5'd4,
                S_LINE  = 5'd5 ;

    // Next state logic aka our state table
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
    end     // state_table

    always @(*) begin: enable_signals
        case (current_state)
            /* set ld_dot to 1 when we've detected a dot */
            S_DOT: begin
                ld_dot = 1'b1;
            end
            /* set ld_line to 1 when we've detected a line */
            S_LINE: begin
                ld_line = 1'b1;
            end
            default: begin
                /* By default make all our signals 0 */
                ld_dot = 1'b0;
                ld_line = 1'b0;
            end
        endcase
    end    // enable_signals
   

    /* current_state registers */
    always@(posedge clock) begin: state_FFs
        /* if reset is pressed, current_state will become S_F1 */
        if (!resetn)
            current_state <= S_F1;
        /* otherwise, current_state goes to next_state */
        else
            current_state <= next_state;
    end // state_FFS
endmodule
