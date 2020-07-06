`default_nettype none

module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	input wire dummy_clk,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on, // state
	input wire debug_sin,
	input wire debug_sin_start,
	

	output [9:0] debug_test_pins_out,
	
	input wire mclk,
	output wire mclk_out,
	output wire bclk,
	output wire lrck,
	output wire audio_data
);	
	wire [9:0] debug_test_pins;
	
	assign mclk_out = mclk;
	assign debug_test_pins_out = ~debug_test_pins;
	assign debug_test_pins[4:3] = 2'b00;
	assign debug_test_pins[9:7] = 3'b000;
	
	wire [39:0] in_data;
	wire data_recv;
	Receiver receiver(
		mon_clk,
		to_mon,
		in_data,
		data_recv
	);
	
	Divider8 sck_div( // generate BCLK
		mclk,
		bclk
	);
	
	wire is_audio, audio_starts, all_1_packet, power_on_packet_R1;
	OpDecoder op_decoder(
		in_data[39:24],
		data_recv,
		is_audio,
		audio_starts,
		all_1_packet,
		power_on_packet_R1
	);
	
	wire audio_req;
	I2SSender i2s(
		mon_clk,
		is_audio,
		in_data[31:0],
		audio_starts,
		audio_req,
		bclk,
		lrck,
		audio_data
	);
	
	assign debug_test_pins[0] = data_recv;
	assign debug_test_pins[2] = is_audio;
	assign debug_test_pins[1] = all_1_packet;

	// DebugDataSender debug_sender(
	// 	mon_clk,
	// 	data_recv,
	// 	in_data,
	// 	debug_sig_on, // state
	// 	debug_test_out_1,
	// 	debug_test_out_2,
	// 	debug_clk,
	// 	debug_sout
	// );
	// assign from_mon = 0;
	
	
	wire [39:0] out_data;
	wire out_valid, power_on_packet_S1;
	
	assign debug_test_pins[5] = audio_req;
	assign debug_test_pins[6] = out_valid;
	
	// wire mon_clk_8;
	// Divider8 mon_clk_div(
	// 	mon_clk,
	// 	mon_clk_8
	// );
	
	Delay #(.DELAY(14000), .W(14)) power_on_packet_delay( // 2.8ms delay
		mon_clk,
		power_on_packet_R1,
		0,
		power_on_packet_S1
	);
	
	OpEncoder op_enc(
		audio_req,
		power_on_packet_S1,
		out_data,
		out_valid
	);

	Sender sender(
		mon_clk,
		out_data,
		out_valid,
		from_mon
	);
	
	//
	// DebugDataReceiver debug_receiver(
	// 	debug_clk,
	// 	debug_sin_start,
	// 	debug_sin,
	// 	out_data,
	// 	out_valid
	// );
	

endmodule
