// `timescale time_unit/time_precision
`timescale 1ns / 1ns

module ps2_keyboard(
    ps2_clock,
    ps2_data,
    data_out,
    data_complete
    );

    /* input from ps/2 port */
    input ps2_clock, ps2_data;
    /* clock feedback for input is done */
    output reg data_complete;
    /* complete input data from ps/2 port */
    output reg [7:0] data_out;

    /* register holding current complete input and previous complete input */
    reg [15:0] data;
    wire upper_data = data[15:8];
    wire lower_data = data[7:0];

    /* keeping track of input */
    reg [4:0] counter;

    /* shift ps/2 data inputs into data register */
    always @(negedge ps2_clock) begin
        if (counter > 0 && counter < 9)
            data <= { ps2_data, data[15:1] };
        if (counter > 8)
            counter <= 4'b0;
        else
            counter <= counter + 1'b1;
    end

    /* loads data from data reg to data_out */
    always @(negedge counter) begin
        if (upper_data == 8'hf0)
            data_complete = 1'b1;
        else
            data_complete = 1'b0;
        data_out = data_complete ? lower_data : 8'b0;
    end
endmodule
