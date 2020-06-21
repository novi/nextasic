`define EMPTY 1'b0 // define state
`define STORED 1'b1


module DebugDataSender(
	input in_clk,
	input store,
	input [39:0] data,
	output reg state = `EMPTY,
	
	input wire out_clk,
	output wire sout
);

	reg [39:0] stored; // stored data
	reg [39:0] tmp;
	reg in_state = `EMPTY;
	reg unsigned [5:0] count = 0; // range 0 to ...
	
	reg wait_for_empty = 0;
	
	assign sout = stored[0];
	

	always@ (posedge out_clk) begin
		if (in_state == `STORED) begin
			if (count == 40)
				begin
					state <= `EMPTY;
					count <= 0;
				end
			else
				begin
					if (count == 0) begin
						stored <= tmp;
						state <= `STORED;
					end
					else
						stored[38:0] <= stored[39:1];
					count <= count + 1'b1;
				end
		end
	end
	
	always@ (posedge in_clk) begin
		if (state == `STORED) begin
			wait_for_empty <= 1;
		end
		if (wait_for_empty == 1) begin
			in_state <= state;
		end
		if (store == 1 && in_state == `EMPTY) begin
			tmp <= data;
			in_state <= `STORED;
		end
	end
	


endmodule


`timescale 1ns/1ns

module test_DebugDataSender;

	reg in_latch = 0;
	reg in_clk = 0;
	reg out_clk = 0;
	reg [39:0] data;
	wire sout;
	wire state;

	parameter IN_CLOCK = 100;
	parameter OUT_CLOCK = 300; 	

	DebugDataSender sender(
		in_clk,
		in_latch,
		data,
		state,
		out_clk,
		sout
	);
	
	always #(IN_CLOCK/2) in_clk = ~in_clk;
	
	always #(OUT_CLOCK/2) out_clk = ~out_clk;
	
	initial begin
		data = 40'b1010100110011001100110011001100110010001;
		#IN_CLOCK in_latch = 1;
		#IN_CLOCK in_latch = 0;
		
		#(OUT_CLOCK*41);
		
		#(OUT_CLOCK*5);
		
		data = 40'b1110100110011001100110011001100110010011;
		#IN_CLOCK in_latch = 1;
		#IN_CLOCK in_latch = 0;
		
		#(OUT_CLOCK*41);
		
		#(OUT_CLOCK*5);
		
		#OUT_CLOCK $stop;
	end
	
endmodule