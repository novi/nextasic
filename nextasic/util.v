module FF2SyncP(
	input wire in,
	input wire out_clk,
	output wire out_data
);

	reg f1, f2;
	
	assign out_data = f2;
	
	always@ (posedge out_clk) begin
		f1 <= in;
		f2 <= f1;
	end
	

endmodule

module FF2SyncN(
	input wire in,
	input wire out_clk,
	output wire out_data
);

	reg f1, f2;
	
	assign out_data = f2;
	
	always@ (negedge out_clk) begin
		f1 <= in;
		f2 <= f1;
	end
	

endmodule

module Divider8(
	input wire clk,
	output wire out
);
	localparam DIVISOR = 4'd8;
	reg[2:0] counter = 0;
	
	assign out = counter[2];
	
	always @(posedge clk) begin
		counter <= counter + 1'b1;
		if(counter >= (DIVISOR-1))
			counter <= 0;
	end
endmodule

`timescale 1ns/1ns

module test_Divider8;

	reg clk = 0;
	wire out;
	
	parameter CLOCK = 100;

	Divider8 div8(
		clk,
		out
	);
	
	always #(CLOCK/2) clk = ~clk;
	
	
	initial begin		
		#(CLOCK*50) $stop;
	end
	
endmodule
