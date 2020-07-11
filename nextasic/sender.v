`default_nettype none

module Sender(
	input wire clk,
	input wire [39:0] in_data,
	input wire in_data_valid,	
	output wire sout, // serial out
	output reg data_loss = 0
);

	localparam READY = 1'b0; // define state
	localparam SEND = 1'b1;
	
	reg [39:0] buffer;
	reg has_buffer_data = 0;
	
	reg [40:0] data = 0;
	reg [5:0] count = 0; // range 0 to 
	
	assign sout = data[40];
	
	reg state = READY;

	always@ (posedge clk) begin
		case (state)
			READY: begin
				if (has_buffer_data & in_data_valid) begin
					data_loss <= 1;
				end
				if (has_buffer_data | in_data_valid) begin
					data[40] <= 1;
					data[39:0] <= has_buffer_data ? buffer : in_data;
					state <= SEND;
					count <= 0;
					if (has_buffer_data)
						has_buffer_data <= 0;
				end
			end
			SEND: begin
				if (in_data_valid) begin
					if (has_buffer_data) begin
						data_loss <= 1;
					end else begin
						buffer <= in_data;
						has_buffer_data <= 1;
					end
				end
				if (count == 41) begin
					state <= READY;
					data_loss <= 0;
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
	wire data_loss;

	
	parameter CLOCK = 100;

	Sender sender(
		clk,
		data,
		data_valid,
		sout,
		data_loss
	);
	
	always #(CLOCK/2) clk = ~clk;

	initial begin
		data_valid = 0;
		data = 40'b1101100110011001100110011001100110010001;
		@(negedge clk);
		data_valid = 1;
		@(negedge clk);
		data_valid = 0;
		#(CLOCK*20);
		
		data = 40'b1101100110011001100110011001100110010011;
		@(negedge clk);
		data_valid = 1;
		@(negedge clk);
		data_valid = 0;
		#(CLOCK*10);
		
		data = 40'b1101100110011001100110011001100110010111;
		@(negedge clk);
		data_valid = 1;
		@(negedge clk);
		data_valid = 0;
		
		#(CLOCK*41*2);
		#(CLOCK*20);
		
		$stop;
	end
	
endmodule

