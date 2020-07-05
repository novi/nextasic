`timescale 1ns/1ns

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

module Delay #(
	parameter DELAY = 10 // max 254
	) (
	input wire clk,
	input wire in_data,
	output reg out_data = 0
);
	reg [7:0] counter;
	reg running = 0;
	
	always@ (negedge clk) begin
		if (counter == DELAY)
			out_data <= 1;
		if (out_data) out_data <= 0;
	end
	
	always@ (posedge clk) begin
		if (running) begin
			if (counter == (DELAY+1)) begin
				running <= 0;
			end
			counter <= counter + 1'b1;
		end else begin
			if (in_data && !running) begin
				counter <= 0;
				running <= 1;
			end
		end
	end
endmodule

module test_Delay;
	reg clk = 0;
	reg in_data = 0;
	wire out;
	
	parameter CLOCK = 100;

	Delay delay(
		clk,
		in_data,
		out
	);
	
	always #(CLOCK/2) clk = ~clk;
	
	initial begin	
		#(CLOCK*5);
		@(negedge clk);
		in_data = 1;
		@(negedge clk);
		in_data = 0;
		#(CLOCK*50) $stop;
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
