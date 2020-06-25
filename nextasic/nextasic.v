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
	input wire debug_sin_start
);
	
	wire [39:0] in_data;
	wire data_recv;
	wire debug_test_out_1;
	wire debug_test_out_2;
	
	assign debug_test_out_pin_1 = ~debug_test_out_1;
	assign debug_test_out_pin_2 = ~debug_test_out_2;
	
	Receiver receiver(
		mon_clk,
		to_mon,
		in_data,
		data_recv
	);

	DebugDataSender debug_sender(
		mon_clk,
		data_recv,
		in_data,
		debug_sig_on, // state
		debug_test_out_1,
		debug_test_out_2,
		debug_clk,
		debug_sout
	);
	assign from_mon = 0;
	
	
	// wire [39:0] out_data;
	// wire out_valid;
	//
	// assign debug_test_out_1 = out_valid;
	//
	// Sender sender(
	// 	debug_clk,
	// 	out_data,
	// 	out_valid,
	// 	mon_clk,
	// 	from_mon
	// );
	//
	// DebugDataReceiver debug_receiver(
	// 	debug_clk,
	// 	debug_sin_start,
	// 	debug_sin,
	// 	out_data,
	// 	out_valid
	// );
	

endmodule
