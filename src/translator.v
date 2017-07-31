module translator(correct, columns, selection, X, Y, colour, draw_full, reset);
	input [1:0] correct;
	input reset;
	input [5:0] columns;
	input [1:0] selection;
	output reg [7:0] X,Y;
	output reg [2:0] colour;
	output reg draw_full;

	reg [4:0] row, column;
	
	always @(*) begin
		// coordinates the positions of squares as position*spacing+offset
		X <= (column*11)+28;
		Y <= (row*8)+30;
	end

	// delays the signal to coordinate with main code
	wire signal;
	assign signal = (correct != 2'b00);
	reg [1:0] correct_reg;

	// on signal evaluate where to draw the next square
	always @(posedge signal, negedge reset) begin
		correct_reg <= correct;
		if (reset == 1'b0) begin 
			// to reset revert all columns and rows to starting positions
			column <= 0;
			row <= 0;
		end
		else if (correct_reg == 2'b01 && row == 5'b00100) begin
			// if correct and we reached the end, move to top of next column
			row <= 5'b0;
			column <= column + 1'b1;
		end
		else if (correct_reg == 2'b01)
			// otherwise, correct results lower the square
			row <= row + 1'b1;
		else
			// otherwise, incorrect results places the square to the top of column
			row <= 5'b0;
	end
	always @(*) begin
		if (selection == 2'b00) begin
			// if we are drawing a 00 blank, we draw a filled red square
			colour <= 3'b100;
			draw_full <= 1'b1;
		end
		else if (selection == 2'b11) begin
			// if we are drawing a 11 dash, we draw a hoolow white square
			colour <= 3'b111;
			draw_full <= 1'b0;
		end
		else if (selection == 2'b01) begin
			// if we are drawing a 01 blank, we draw a filled white square
			colour <= 3'b111;
			draw_full <= 1'b1;
		end
	end
endmodule
	

