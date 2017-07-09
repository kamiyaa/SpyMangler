// `timescale time_unit/time_precision
`timescale 1ns / 1ns

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

    always @(posedge clock_in) begin
        if (rate_counter == rate)
            rate_counter <= 0;
        else
            rate_counter <= rate_counter + 1'b1;
    end

    assign clock_out = (rate_counter == rate) ? 1'b1 : 1'b0;

endmodule
