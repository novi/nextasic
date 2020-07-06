`default_nettype none

module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	input wire dummy_clk,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on, // state
	output wire debug_test_out_pin_1,
	output wire debug_test_out_pin_2,
	input wire debug_sin,
	input wire debug_sin_start,
	
	input wire mclk,
	output wire mclk_out,
	output wire bclk,
	output wire lrck,
	output wire audio_data
);
	
	wire [39:0] in_data;
	wire data_recv;
	wire debug_test_out_1;
	wire debug_test_out_2;
	
	assign mclk_out = mclk;
	assign debug_test_out_pin_1 = ~debug_test_out_1;
	assign debug_test_out_pin_2 = ~debug_test_out_2;
	
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
	
	assign debug_test_out_1 = is_audio;
	

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
	wire out_valid, audio_req_delay;
	
	assign debug_test_out_2 = audio_req;
	
	// Delay #(.DELAY(35)) delay_audio(
	// 	mon_clk,
	// 	audio_req,
	// 	data_recv,
	// 	audio_req_delay
	// );
	
	OpEncoder op_enc(
		audio_req,
		0,
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
