// `timescale time_unit/time_precision
`timescale 1ns / 1ns

/* rate divider module*/
/* given the clock_in, and the rate wanted, the custom rate divider
adapts the clock_out rate to be equal to the desired input rate*/
module rate_divider(
    // input
    clock_in,
    rate,

    // output
    clock_out);

    input clock_in;
    input [27:0] rate;
    output clock_out;

    reg [27:0] rate_counter;

    /* adds 1 binary to rate_counter if rate_counter not equal to rate*/
    // sensitive when clock_in is positive
    always @(posedge clock_in) begin
        if (rate_counter == rate)
            rate_counter <= 0;
        else
            rate_counter <= rate_counter + 1'b1;
    end

    // assigns clock_out value based on binary 1 or 0
    assign clock_out = (rate_counter == rate) ? 1'b1 : 1'b0;

endmodule
