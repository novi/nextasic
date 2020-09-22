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

	output wire [9:0] debug_test_pins_out,
	input wire debug_sw_0,
	input wire debug_sw_1
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
	
	wire is_audio_sample, audio_starts, audio_22khz, end_audio_sample, all_1_packet, power_on_packet_R1, keyboard_led_update,
		 attenuation_data_valid;
	wire [7:0] attenuation_data;
	OpDecoder op_decoder(
		in_data[39:16],
		data_recv,
		is_audio_sample,
		audio_starts,
		audio_22khz,
		end_audio_sample,
		all_1_packet,
		power_on_packet_R1,
		keyboard_led_update,
		attenuation_data_valid,
		attenuation_data
	);
	
	wire audio_sample_request_mode, audio_sample_request_tick;
	I2SSender i2s(
		mon_clk,
		is_audio_sample,
		in_data[31:0],
		audio_starts,
		end_audio_sample,
		audio_22khz,
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
		keyboard_led_update,
		in_data[17:16],
		keyboard_data_ready,
		is_mouse_data,
		keyboard_data,
		from_kb,
		to_kb,
		//debug_test_pins[4:0]
	);
	
	wire is_muted, db_val_valid;
	wire [5:0] lch_db;
	wire [5:0] rch_db;
	wire [7:0] att_debug_out;
	Attenuation att(
		mon_clk,
		attenuation_data_valid,
		attenuation_data,
		is_muted,
		lch_db,
		rch_db,
		db_val_valid
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
	
	// assign debug_test_pins[0] = to_mon;
	assign debug_test_pins[5:0] = debug_sw_0 ? lch_db : rch_db;
	// assign debug_test_pins[1] = end_audio_sample;
	// assign debug_test_pins[2] = audio_22khz;
	// assign debug_test_pins[3] = audio_starts;
	// assign debug_test_pins[4] = audio_sample_request_tick;
	// assign debug_test_pins[5] = audio_sample_request_mode;
	// assign debug_test_pins[6] = is_audio_sample;
	// assign debug_test_pins[6] = attenuation_data_valid;
	// assign debug_test_pins[8] = keyboard_led_update;
	assign debug_test_pins[6] = is_muted;
	// assign debug_test_pins[7:0] = att_debug_out;
	assign debug_test_pins[7] = attenuation_data_valid;
	// assign debug_test_pins[9] = mon_clk;
	assign debug_test_pins[8] = db_val_valid;
	assign debug_test_pins[9] = to_mon;
	
	Delay #(.DELAY(14000), .W(14)) power_on_packet_delay( // 2.8ms delay
		mon_clk,
		power_on_packet_R1,
		0,
		power_on_packet_S1
	);
	
	OpEncoder op_enc(
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
