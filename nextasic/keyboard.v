`default_nettype none

module Keyboard(
	input wire clk, // mon clk
	output reg data_ready = 0,
	output reg is_mouse_data = 0, // 0 is keyboard data
	output reg [15:0] keyboard_data, // or mouse data
	input wire keyboard_data_retrieved,
	input wire from_kb,
	output reg to_kb = 1
);

	localparam KEY_CLK = 5'd26; // 54us
	
	localparam QUERY_KEYBOARD = 1'b0;
	localparam QUERY_MOUSE = 1'b1;
	
	localparam READY_NOT = 2'b00;
	localparam READY_PENDING = 2'b01;
	localparam READY_READY = 2'b10;
	
	//reg keyboard_ready = 0;
	reg [1:0] ready_state = READY_NOT;
	reg [5:0] send_count = 0;
	reg is_send_query = 0; // if is_send_query, the packet size is 8bit, otherwise 21bit
	reg [20:0] tmp_send; // 21 bit
	reg is_sending = 0;
	reg query_state = QUERY_KEYBOARD;
	reg data_receved = 0;
	reg [4:0] key_clk_count = 0;
	
	reg is_recving = 0;
	//reg [19:0] tmp_recv; // 19bit
	reg [5:0] recv_count;
	reg [4:0] recv_delay;
	
	
	always@ (posedge clk) begin
		if (key_clk_count == KEY_CLK) begin
			key_clk_count <= 0;
			// keyboard clk tick
			send_count <= send_count + 1'b1;
			if (send_count == 6'd40) begin
				if (ready_state == READY_NOT) begin
					tmp_send <= 21'b111101111110000000000;
					is_send_query <= 0;
					ready_state <= READY_PENDING;
				end else begin
					if (query_state == QUERY_KEYBOARD)
						tmp_send <= 21'b00001000xxxxxxxxxxxxx;
					else
						tmp_send <= 21'b10001000xxxxxxxxxxxxx;
					query_state <= ~query_state;
					is_send_query <= 1;
				end
				to_kb <= 0; // start bit
				is_sending <= 1;
				send_count <= 0;
				if (data_receved) begin
					data_receved <= 0;
				end else begin
					// no data
					if (ready_state == READY_READY)
						ready_state <= READY_NOT; // need reset
				end
			end else if ((is_send_query && send_count == 5'd8) || (!is_send_query && send_count == 5'd21)) begin
				// end of the packet sending
				to_kb <= 1;
				is_sending <= 0;
			end else if (is_sending && !is_recving) begin
				to_kb <= tmp_send[20];
				tmp_send[20:1] <= tmp_send[19:0];
			end
		end else begin
			key_clk_count = key_clk_count + 1'b1;
		end
	
		// from_kb sampling
		if (!is_sending && from_kb == 0 && !is_recving) begin
			is_recving <= 1;
			recv_count <= 0;
			recv_delay <= 0;
		end
		
		if (is_recving) begin
			if (recv_count == 5'd21) begin
				// recv done
				is_recving <= 0;
				casex (tmp_send)
					21'b11100000000110000000?: begin // ready response
						ready_state <= READY_READY;
						data_receved <= 1;
					end
					21'b10????????01?????????: begin
						keyboard_data[7:0] <= tmp_send[8:1];
						keyboard_data[15:8] <= tmp_send[18:11];
						data_receved <= 1;
						data_ready <= 1;
						is_mouse_data <= query_state;
					end
				endcase
			end else if (recv_count == 0 && recv_delay == 5'd12) begin 
				// start getting data from kb
				recv_delay <= 0;
				recv_count <= 5'd1; // recv_count <= recv_count + 1'b1;
			end else if (recv_delay == KEY_CLK) begin
				recv_delay <= 0;
				tmp_send[20:0] <= {from_kb, tmp_send[20:1]};
				recv_count <= recv_count + 1'b1;
			end else
				recv_delay <= recv_delay + 1'b1;
		end
		
		if (keyboard_data_retrieved)
			data_ready <= 0;
	end

endmodule

`timescale 1ns/1ns

module test_Keyboard;
	reg clk = 0;
	reg from_kb = 1;
	reg keyboard_data_retrieved = 0;
	wire to_kb, data_ready, is_mouse_data;
	wire [15:0] keyboard_data;
	
	parameter CLOCK = 200;
	
	parameter KEY_SIG_DELAY = 5400;
	
	localparam PACKET_READY = 21'b000000001100000000111;
	localparam PACKET_DATA = 21'b011011000100000000101;

	Keyboard keyboard(
		clk,
		data_ready,
		is_mouse_data,
		keyboard_data,
		keyboard_data_retrieved,
		from_kb,
		to_kb
	);
	
	always #(CLOCK/2) clk = ~clk;
	
	task KeyboardRes(
		input [20:0] data
	);
		integer i;
		begin
			for(i = 0; i < 21; i = i + 1) begin
			      from_kb = data[20-i];
				  #(KEY_SIG_DELAY);
			end
			from_kb = 1;
		end
	endtask
	
	initial begin	
		#(CLOCK*5);
		//@(negedge clk) from_kb = 1;
		@(negedge to_kb);
		#(KEY_SIG_DELAY*21); // reset packet
		
		#(KEY_SIG_DELAY*5);
		
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // kb query packet
		
		#(KEY_SIG_DELAY*3);
		
		// recv response
		KeyboardRes(PACKET_READY);
		
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // mouse query packet
		
		#(KEY_SIG_DELAY*3);
		
		// recv response
		KeyboardRes(PACKET_READY);
		
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // kb query packet
		
		#(KEY_SIG_DELAY*3);
		
		// recv response
		KeyboardRes(PACKET_DATA);
		#(CLOCK*5);
		
		// get data from buffer
		keyboard_data_retrieved = 1;
		@(negedge clk) keyboard_data_retrieved = 0;
		
		#(KEY_SIG_DELAY*200);
		
		$stop;
	end
	
endmodule

//TODO: module test_Keyboard_no_connect;

