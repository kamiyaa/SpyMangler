module translator(correct, signal, columns, selection, X, Y, colour, draw_full);
	input correct, signal;
	input [5:0] columns;
	input [1:0] selection;

	output reg [7:0] X,Y;
	output reg [2:0] colour;
	output reg draw_full;

	reg [4:0] row, column;

	always @(*) begin
		X <= column*20;
		Y <= row*4;
	end

	always @(posedge signal) begin
		if (correct && row == 5'b00100) begin
			row <= 5'b0;
			column <= column + 1'b1;
		end
		else if (correct)
			row <= row + 1'b1;
		else
			row <= 5'b0;
	end
	always @(*) begin
		if (selection == 2'b00) begin
			colour <= 3'b100;
			draw_full <= 1'b1;
		end
		else if (selection == 2'b11) begin
			colour <= 3'b111;
			draw_full <= 1'b0;
		end
		else if (selection == 2'b01) begin
			colour <= 3'b111;
			draw_full <= 1'b1;
		end
	end
endmodule
	

