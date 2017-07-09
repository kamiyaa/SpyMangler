// `timescale time_unit/time_precision
`timescale 1ns / 1ns

module input_module(
    // Inputs
    clock,
    input_in,
    resetn,

    // Outputs
    ld_dot,
    ld_line
    );

    input clock;
    input input_in;
    input resetn;

    output reg ld_dot, ld_line;

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
            /*                                  not pressed     pressed */
            S_F1:       next_state = input_in ? S_F1    :       S_F2;
            S_F2:       next_state = input_in ? S_DOT   :       S_F3;
            S_F3:       next_state = input_in ? S_F1    :       S_F4;
            S_F4:       next_state = input_in ? S_LINE  :       S_F2;
            S_DOT:      next_state = input_in ? S_F1    :       S_F2;
            S_LINE:     next_state = input_in ? S_F1    :       S_F2;
            default:    next_state = S_F1;
        endcase
    end     // state_table

    // Output logic aka all of our datapath control signals
    always @(*) begin: enable_signals
        // By default make all our signals 0
        ld_dot = 1'b0;
        ld_line = 1'b0;
        case (current_state)
            S_DOT: begin
                ld_dot = 1'b1;
            end
            S_LINE: begin
                ld_line = 1'b1;
            end
        endcase
    end    // enable_signals
   

    // current_state registers
    always@(posedge clock) begin: state_FFs
        if (!resetn)
            current_state <= S_F1;
        else
            current_state <= next_state;
    end // state_FFS
endmodule
