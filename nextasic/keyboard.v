`default_nettype none

module Keyboard(
	input wire clk, // mon clk
	output reg data_ready = 0,
	output reg is_mouse_data = 0, // 0 is keyboard data
	output reg [15:0] keyboard_data, // or mouse data
	input wire keyboard_data_retrieved,
	input wire from_kb,
	output reg to_kb = 1,
	output wire [4:0] debug
);

	localparam KEY_CLK = 9'd264; // 53us
	localparam KEY_CLK_HALF = 9'd131;
	
	localparam QUERY_KEYBOARD = 1'b0;
	localparam QUERY_MOUSE = 1'b1;
	
	localparam READY_NOT = 2'b00;
	localparam READY_PENDING = 2'b01;
	localparam READY_READY = 2'b10;
	
	//reg keyboard_ready = 0;
	reg [1:0] ready_state = READY_NOT;
	reg [5:0] send_count = 0;
	reg is_send_query = 0; // if is_send_query, the packet size is 8bit, otherwise 21bit
	reg [20:0] tmp; // 21 bit
	reg is_sending = 0;
	reg query_state = QUERY_KEYBOARD;
	reg data_receved = 0;
	reg [8:0] key_clk_count = 0;
	
	reg is_recving = 0;
	reg [4:0] recv_count;
	reg [8:0] recv_delay;
	reg [1:0] pending_count;
	reg can_recv_start = 0;
	
	assign debug[2] = data_receved;
	assign debug[1:0] = ready_state;
	assign debug[3] = is_recving;
	assign debug[4] = recv_count == 5'd21 ? 1 : 0;
	reg debug_packet_loss = 0;
	
	always@ (posedge clk) begin
		if (key_clk_count == KEY_CLK) begin
			key_clk_count <= 0;
			// keyboard clk tick
			send_count <= send_count + 1'b1;
			if (send_count == 6'd40) begin
				if (ready_state == READY_NOT) begin
					tmp <= 21'b111101111110000000000;
					is_send_query <= 0;
					ready_state <= READY_PENDING;
					pending_count <= 0;
				end else begin
					if (query_state == QUERY_KEYBOARD)
						tmp <= 21'b00001000xxxxxxxxxxxxx;
					else
 						tmp <= 21'b10001000xxxxxxxxxxxxx;
					if (!data_ready)
						is_mouse_data <= (query_state == QUERY_KEYBOARD ? 1'b0 : 1'b1);
					query_state <= ~query_state;
					is_send_query <= 1;
					can_recv_start <= 1;
				end
				to_kb <= 0; // start bit
				is_sending <= 1;
				send_count <= 0;
				if (data_receved) begin
					data_receved <= 0;
					pending_count <= 0;
				end else begin
					// no data
					if (ready_state == READY_PENDING) 
						if (pending_count == 2'd3) begin
							ready_state <= READY_NOT; // need reset
						end else begin
							pending_count <= pending_count + 1'b1;
						end
					else if (ready_state == READY_READY) // TODO: 
						ready_state <= READY_NOT;
				end
			end else if ((is_send_query && send_count == 5'd8) || (!is_send_query && send_count == 5'd21)) begin
				// end of the packet sending
				to_kb <= 1;
				is_sending <= 0;
			end else if (is_sending && !is_recving) begin
				to_kb <= tmp[20];
				tmp[20:1] <= tmp[19:0];
			end
		end else begin
			key_clk_count = key_clk_count + 1'b1;
		end
	
		// from_kb sampling
		if (can_recv_start && !is_sending && from_kb == 0 && !is_recving) begin
			is_recving <= 1;
			recv_count <= 0;
			recv_delay <= 0;
			can_recv_start <= 0;
		end else if (is_recving) begin
			if (recv_count == 5'd21) begin
				// recv done
				is_recving <= 0;
				// can_recv_start <= 0;
				casex (tmp)
					21'b10000000001100000000?: begin // ready response
						ready_state <= READY_READY;
						data_receved <= 1;
					end
					21'b0????????010?????????: begin // TODO: need ready
						data_receved <= 1;
						if (!data_ready) begin // already has data, skip this recv
							keyboard_data[7:0] <= tmp[8:1];
							keyboard_data[15:8] <= tmp[19:12];
							data_ready <= 1;
							debug_packet_loss <= 0;
						end else begin
							debug_packet_loss <= 1;
						end
					end
				endcase
			end else if (recv_count == 0 && recv_delay == KEY_CLK_HALF) begin 
				// if (from_kb == 0) begin
					// start getting data from kb
					recv_delay <= 0;
					recv_count <= recv_count + 1'b1;
				// end else begin
				// 	// not valid data, abort recving
				// 	is_recving <= 0;
				// end		
			end else if (recv_delay == KEY_CLK) begin
				recv_delay <= 0;
				tmp[20:0] <= {from_kb, tmp[20:1]};
				recv_count <= recv_count + 1'b1;
			end else begin
				recv_delay <= recv_delay + 1'b1;
			end
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
	
	parameter KEY_SIG_DELAY = 53000;
	
	localparam PACKET_READY = 21'b000000000110000000001;
	localparam PACKET_DATA =  21'b011011001010000000010;

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
		
		// 
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // mouse query packet
		#(KEY_SIG_DELAY*3);
		KeyboardRes(PACKET_READY);
		
		//
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // kb query packet
		#(KEY_SIG_DELAY*3);
		KeyboardRes(PACKET_READY);
		
		//
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // mouse query packet
		#(KEY_SIG_DELAY*3);
		KeyboardRes(PACKET_READY);
		
		//
		@(negedge to_kb);
		#(KEY_SIG_DELAY*8); // kb query packet
		#(KEY_SIG_DELAY*3);
		KeyboardRes(PACKET_READY);
		
		
		
		
		#(KEY_SIG_DELAY*200);
		
		$stop;
	end
	
endmodule

//TODO: module test_Keyboard_no_connect;

