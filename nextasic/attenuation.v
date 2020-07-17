`default_nettype none

module Attenuation(
	input wire clk,
	input wire attenuation_data_valid,
	input wire [7:0] data_in, // attenuation_data from NeXT hardware
	output reg is_muted = 1,
	output reg [5:0] lch_db = 6'd43, // 43(-86dB) to 0(0dB)
	output reg [5:0] rch_db = 6'd43
	// TODO: output reg db_val_valid = 0
	//output wire [7:0] debug_out
	//output wire value_updated, // TODO:
);

	localparam VAL1_0 = 8'h02;
	localparam VAL1_1 = 8'h06;
	//localparam VAL0_0 = 8'h00;
	localparam VAL0_1 = 8'h04;
	
	localparam S_VAL1_0 = 3'd1;
	localparam S_VAL1_1 = 3'd2;
	localparam S_VAL0_0_OR_S_0 = 3'd0;
	localparam S_VAL0_1 = 3'd3;
	localparam S_1 = 3'd4;
	localparam S_INVALID = 3'd7;
	
	localparam CMD_INVALID = 2'b00;
	localparam CMD_L_CH = 2'b01;
	localparam CMD_R_CH = 2'b10;
	localparam CMD_BOTH_CH = CMD_L_CH | CMD_R_CH;
	
	reg [2:0] state = S_VAL0_0_OR_S_0; 
	reg [10:0] buff;
	reg [3:0] count = 0;
	reg initialized = 0;
	
	wire [1:0] cmd;
	assign cmd = buff[7:6];
	wire [5:0] att_data;
	assign att_data = buff[5:0];
	
	// assign debug_out = buff[7:0];
	
	reg [2:0] valid_state;
	always@ (*) begin
		case ( (data_in & 8'h0f) )
			0:
				valid_state = S_VAL0_0_OR_S_0;
			8'h01:
				valid_state = S_1;
			VAL1_0:
				valid_state = S_VAL1_0;
			VAL1_1:
				valid_state = S_VAL1_1;
			VAL0_1:
				valid_state = S_VAL0_1;
			default:
				valid_state = S_INVALID;
		endcase
	end
	
	// wire [7:0] data_;
	// assign data_ = data_in & 8'h0f;
	// wire [2:0] valid_state;
	// assign valid_state = (data_ == 0) ? S_VAL0_0_OR_S_0 : (
	// 		(data_ == 8'h01) ? S_1 : (
	// 			(data_ == VAL1_0) ? S_VAL1_0 : (
	// 				(data_ == VAL1_1) ? S_VAL1_1 : (
	// 					(data_ == VAL0_1) ? S_VAL0_1 : S_INVALID
	// 				)
	// 			)
	// 		)
	// 	);
		
	wire is_eof_packet;
	assign is_eof_packet = (count == 4'd11);

	always@ (posedge clk) begin
		if (attenuation_data_valid) begin
			is_muted <= (data_in & 8'h10) ? 1'b1 : 1'b0;
			case (valid_state)
				S_VAL0_0_OR_S_0: begin
					if (!is_eof_packet && state != S_VAL0_1 && state != S_VAL1_1) begin
						// reset current state
						buff <= 0;
						count <= 0;
						initialized <= 1;
					end
				end
				S_VAL1_1: if (initialized && state == S_VAL1_0) begin
					buff[0] <= 1'b1;
					buff[10:1] <= buff[9:0];
					count <= count + 1'b1;
				end
				S_VAL0_1: if (initialized && state == S_VAL0_0_OR_S_0) begin
					buff[0] <= 1'b0;
					buff[10:1] <= buff[9:0];
					count <= count + 1'b1;
				end
				// buff[10:8] is header will be 111
				S_1: if (initialized && buff[10:8] == 3'b111 && state == S_VAL0_0_OR_S_0 && is_eof_packet) begin
					case (cmd)
						CMD_L_CH:
							lch_db <= att_data;
						CMD_R_CH:
							rch_db <= att_data;
						CMD_BOTH_CH: begin
							lch_db <= att_data;
							rch_db <= att_data;
						end
						CMD_INVALID: begin						
						end
					endcase
					initialized <= 0;
					count <= 0;
				end
				default: begin
				end
			endcase	
			state <= valid_state;
		end
	end

endmodule


`timescale 1ns/1ns

module test_Attenuation;

	reg clk = 0;
	reg attenuation_data_valid = 0;
	reg [7:0] data;
	wire is_muted;
	wire [5:0] lch_db;
	wire [5:0] rch_db;

	parameter CLOCK = 100;

	Attenuation att(
		clk,
		attenuation_data_valid,
		data,
		is_muted,
		lch_db,
		rch_db
	);
	
	always #(CLOCK/2) clk = ~clk;

	task PacketSend(
		input [7:0] in_data
	);
		begin
			data = in_data;
			@(negedge clk);
			attenuation_data_valid = 1;
			@(negedge clk);
			attenuation_data_valid = 0;
			#(CLOCK*5);
		end
	endtask
	
	initial begin
		#(CLOCK*5);
		PacketSend(8'h17); // mute packet
		
		
		// test for att both ch
		PacketSend(8'h00);
		
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1, header
		
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1, cmd
		
		PacketSend(8'h00);
		PacketSend(8'h04); // 0
		PacketSend(8'h00);
		PacketSend(8'h04); // 0
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h00);
		PacketSend(8'h04); // 0
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1, att data
		
		PacketSend(8'h00);
		PacketSend(8'h01); // commit 
		PacketSend(8'h00);
		
		// test with invalid packet
		PacketSend(8'h00);
		PacketSend(8'h00);
		
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1
		PacketSend(8'h02);
		PacketSend(8'h06); // 1, header
		
		PacketSend(8'h04); // invalid packet
		PacketSend(8'h00);
		
		$stop;
	end
	
endmodule


