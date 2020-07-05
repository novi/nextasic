module Sender(
	input wire clk,
	input wire [39:0] in_data,
	input wire in_data_valid,	
	output wire sout // serial out
);

	localparam READY = 1'b0; // define state
	localparam SEND = 1'b1;
	
	reg [40:0] data = 0;
	reg [5:0] count = 0; // range 0 to 
	
	assign sout = data[40];
	
	reg state = READY;

	always@ (posedge clk) begin
		
	end

	always@ (negedge clk) begin
		case (state)
			READY: if (in_data_valid) begin
				data[40] <= 1;
				data[39:0] <= in_data;
				state <= SEND;
				count <= 0;
			end
			SEND: begin
				if (count == 41) begin
					state <= READY;
				end else begin
					data[0] <= 0;
					data[40:1] <= data[39:0];
					count <= count + 1'b1;
				end
			end
		endcase
	end
	
endmodule

`timescale 1ns/1ns

module test_Sender;

	reg clk = 0;
	reg [39:0] data;
	reg data_valid = 0;
	wire sout;

	
	parameter CLOCK = 100;

	Sender sender(
		clk,
		data,
		data_valid,
		sout
	);
	
	always #(CLOCK/2) clk = ~clk;

	initial begin
		data_valid = 0;
		data = 40'b1101100110011001100110011001100110010001;
		#(CLOCK*2);
		data_valid = 1;
		#(CLOCK*2);
		data_valid = 0;
		
		#(CLOCK*48);
		#(CLOCK*20);
		
		$stop;
	end
	
endmodule

