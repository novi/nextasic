`default_nettype none

module nextasic(
	// for NeXT computer
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	// for Keyboard
	input wire from_kb,
	output wire to_kb,
	
	// for DAC
	input wire mclk,
	output wire mclk_out,
	output wire bclk,
	output wire lrck,
	output wire audio_data,
	
	//
	input wire dummy_clk,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on, // state
	input wire debug_sin,
	input wire debug_sin_start,

	output [9:0] debug_test_pins_out
);	
	wire [9:0] debug_test_pins;
	
	assign mclk_out = mclk;
	//assign debug_test_pins_out = ~debug_test_pins;
	assign debug_test_pins_out = debug_test_pins;
	// assign debug_test_pins[4:3] = 2'b00;
	//assign debug_test_pins[9:7] = 3'b000;
	
	wire [39:0] in_data;
	wire data_recv;
	Receiver receiver(
		mon_clk,
		to_mon,
		in_data,
		data_recv
	);
	
	Divider#(.DIVISOR(8), .W(3)) sck_div( // generate BCLK
		mclk,
		bclk
	);
	
	wire is_audio_sample, audio_starts, all_1_packet, power_on_packet_R1, keyboard_led_update;
	OpDecoder op_decoder(
		in_data[39:24],
		data_recv,
		is_audio_sample,
		audio_starts,
		all_1_packet,
		power_on_packet_R1,
		keyboard_led_update
	);
	
	wire audio_sample_request_mode, audio_sample_request_tick;
	I2SSender i2s(
		mon_clk,
		is_audio_sample,
		in_data[31:0],
		audio_starts,
		audio_sample_request_mode,
		audio_sample_request_tick,
		bclk,
		lrck,
		audio_data
	);
	
	wire [15:0] keyboard_data;
	wire keyboard_data_ready, is_mouse_data;
	Keyboard keyboard(
		mon_clk,
		keyboard_data_ready,
		is_mouse_data,
		keyboard_data,
		from_kb,
		to_kb,
		//debug_test_pins[4:0]
	);
	
	// assign debug_test_pins[0] = data_recv;
	// assign debug_test_pins[2] = is_audio_sample;
	// assign debug_test_pins[1] = all_1_packet;

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
	wire out_valid, power_on_packet_S1, data_loss;
	
	assign debug_test_pins[0] = to_mon;
	assign debug_test_pins[3] = audio_starts;
	assign debug_test_pins[4] = audio_sample_request_tick;
	assign debug_test_pins[5] = audio_sample_request_mode;
	assign debug_test_pins[6] = out_valid;
	assign debug_test_pins[7] = keyboard_data_ready;
	assign debug_test_pins[8] = data_loss;
	assign debug_test_pins[9] = from_mon;
	
	Delay #(.DELAY(14000), .W(14)) power_on_packet_delay( // 2.8ms delay
		mon_clk,
		power_on_packet_R1,
		0,
		power_on_packet_S1
	);
	
	OpEncoder op_enc(
		0,
		power_on_packet_S1,
		keyboard_data_ready,
		is_mouse_data,
		keyboard_data,
		out_data,
		out_valid
	);

	Sender sender(
		mon_clk,
		out_data,
		out_valid,
		audio_sample_request_mode,
		audio_sample_request_tick,
		from_mon,
		data_loss
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
