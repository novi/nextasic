`default_nettype none

module Sender(
	input wire clk,
	input wire [39:0] in_data,
	input wire in_data_valid,
	input wire audio_sample_request_mode,
	input wire audio_sample_request_tick,
	output wire sout, // serial out
	output reg data_loss = 0
);

	localparam READY = 1'b0; // define state
	localparam SEND = 1'b1;
	
	reg [39:0] buffer;
	reg has_buffer_data = 0;
	
	reg [40:0] data = 0;
	reg [6:0] count = 0; // range 0 to 
	
	assign sout = data[40];
	
	reg state = READY;
	
	wire packet_send_end;
	assign packet_send_end = count == (41+3);

	always@ (posedge clk) begin
		case (state)
			READY: begin
				if (audio_sample_request_tick) begin
					if (audio_sample_request_mode) begin
						data[40] <= 1;
						data[39:0] <= 40'h0700000000; // audio sample request packet
					end else begin
						data[40] <= 0;
						data[39:0] <= 0;
					end
					state <= SEND;
					count <= 0;
				end
				
				if (in_data_valid) begin
					if (has_buffer_data)
						data_loss <= 1;
					else begin
						has_buffer_data <= 1;
						buffer <= in_data;
					end
				end
			end
			SEND: begin
				if (packet_send_end) begin
					data_loss <= has_buffer_data & in_data_valid;
					if (has_buffer_data) begin
						data[40] <= 1;
						data[39:0] <= buffer;
						has_buffer_data <= 0;
					end else if (in_data_valid) begin
						buffer <= in_data;
						has_buffer_data <= 1;
					end
					count <= count + 1'b1;
				end else if (count == (41+3+41+1)) begin
					state <= READY;
					data_loss <= 0;
				end else begin
					data[0] <= 0;
					data[40:1] <= data[39:0];
					count <= count + 1'b1;
				end
				if (!packet_send_end) begin
					if (in_data_valid) begin
						if (has_buffer_data)
							data_loss <= 1;
						else begin
							has_buffer_data <= 1;
							buffer <= in_data;
						end
					end
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
	reg audio_sample_request_tick = 0;
	reg audio_sample_request_mode = 0;
	wire sout;
	wire data_loss;

	
	parameter CLOCK = 100;
	parameter AUDIO_REQ_INTERVAL = 114;

	Sender sender(
		clk,
		data,
		data_valid,
		audio_sample_request_mode,
		audio_sample_request_tick,
		sout,
		data_loss
	);
	
	always #(CLOCK/2) clk = ~clk;
	always #(CLOCK*AUDIO_REQ_INTERVAL) begin
		@(negedge clk);
		audio_sample_request_tick = 1;
		@(negedge clk);
		audio_sample_request_tick = 0;
	end

	task sendData;
		begin
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
		end
	endtask
	
	initial begin
		// regular send
		sendData();
		#(CLOCK*AUDIO_REQ_INTERVAL +40);
		
		// with audio sample request
		audio_sample_request_mode = 1;
		
		#(CLOCK*60);
		sendData();
		#(CLOCK*AUDIO_REQ_INTERVAL*2);
		audio_sample_request_mode = 0;
		#(CLOCK*AUDIO_REQ_INTERVAL*2);
		
		$stop;
	end
	
endmodule

