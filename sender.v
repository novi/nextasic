module Sender(
	input wire [39:0] in_data,
	input wire in_valid,
	input wire out_clk,
	output wire sout // serial out
);

	localparam READY = 1'b0; // define state
	localparam SEND = 1'b1;

	reg [39:0] data_tmp;
	reg [40:0] data;
	reg [5:0] count = 0; // range 0 to 
	
	assign sout = data[0];
	reg state1 = READY;
	reg state2 = READY;
	reg data_tmp_ready = 0;

	always@ (posedge in_valid) begin
		data_tmp <= in_data;
		data_tmp_ready <= 1;
	end

	always@ (negedge out_clk) begin
		if (state2 == SEND) begin
			if (count == 41) begin
				state1 <= READY;
				state2 <= READY;
			end else begin
				data[40] <= 0;
				data[39:0] <= data[40:1];
				count <= count + 1'b1;
			end
		end
	end
	
	always@ (posedge out_clk) begin
		if (state1 == READY && state2 == READY) begin
			if (data_tmp_ready) begin
				data[0] <= 1;
				data[40:1] <= data_tmp;
				state1 <= SEND;
				data_tmp_ready <= 0;
			end
		end
		if (state1 == SEND)
			state2 <= SEND;
	end

endmodule


`timescale 1ns/1ns

module test_Sender;

	reg clk = 0;
	reg [39:0] data;
	reg in_valid = 0;
	wire sout;

	parameter CLOCK = 100;

	Sender sender(
		data,
		in_valid,
		clk,
		sout
	);
	
	always #(CLOCK/2) clk = ~clk;

	initial begin
		in_valid = 0;
		data = 40'b1101100110011001100110011001100110010001;
		#(CLOCK);
		in_valid = 1;
		#(CLOCK);
		in_valid = 0;
		
		#(CLOCK*45);
		
		$stop;
	end
	
endmodule

