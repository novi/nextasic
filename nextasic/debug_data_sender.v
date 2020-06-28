`define EMPTY 1'b0 // define state
`define STORED 1'b1


module DebugDataSender(
	input wire in_clk,
	input wire data_valid, // data valid
	input wire [39:0] data,
	output reg state_out = `EMPTY,
	output wire debug_test_out_1, // TODO: debug
	output wire debug_test_out_2, // TODO: debug
	input wire out_clk,
	output wire sout
);

	reg state = `EMPTY;
	reg [39:0] stored; // stored data
	reg [39:0] tmp; // TODO: double FF?
	reg in_state = `EMPTY;
	reg [5:0] count = 0; // range 0 to ...
	reg wait_for_empty = 0;
	reg in_state_ack = 0;
	
	assign sout = stored[39];
	
	assign debug_test_out_1 = in_state;
	assign debug_test_out_2 = wait_for_empty;
	
	always@ (posedge out_clk) begin
		state_out <= in_state;
	end

	always@ (negedge out_clk) begin
		if (wait_for_empty) begin
			in_state_ack <= 0;
		end
		if (in_state == `STORED && state == `EMPTY) begin
			in_state_ack <= 1;
			state <= `STORED;
			count <= 1;
			stored <= tmp;
		end else begin
			if (count == 40) begin
				state <= `EMPTY;
			end else begin
				stored[39:1] <= stored[38:0];
				count <= count + 1'b1;
			end
		end
	end
	
	always@ (posedge in_clk) begin
		if (in_state_ack) begin
			wait_for_empty <= 1;
			in_state <= `EMPTY;
		end
		if (wait_for_empty && state == `EMPTY) begin
			wait_for_empty <= 0;
		end
		if (data_valid && in_state == `EMPTY && wait_for_empty == 0) begin
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
	wire int_state_1;
	wire int_state_2;

	parameter IN_CLOCK = 100;
	parameter OUT_CLOCK = IN_CLOCK*110; 	

	DebugDataSender sender(
		in_clk,
		in_latch,
		data,
		state,
		int_state_1,
		int_state_2,
		out_clk,
		sout
	);
	
	always #(IN_CLOCK/2) in_clk = ~in_clk;
	
	always #(OUT_CLOCK/2) out_clk = ~out_clk;
	
	initial begin
		data = 40'b1010100110011001100110011001100110010001;
		#IN_CLOCK in_latch = 1;
		#IN_CLOCK in_latch = 0;
		
		
		#(OUT_CLOCK*20);
		data = 40'b1010100110011001100110011001100110000001;
		#IN_CLOCK in_latch = 1;
		#IN_CLOCK in_latch = 0;
		#(OUT_CLOCK*20);
		
		#(OUT_CLOCK*7);
		
		data = 40'b1110100110011001100110011001100110010011;
		#IN_CLOCK in_latch = 1;
		#IN_CLOCK in_latch = 0;
		
		#(OUT_CLOCK*41);
		
		#(OUT_CLOCK*5);
		
		#OUT_CLOCK $stop;
	end
	
endmodule