module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	input wire dummy_clk,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on, // state
	output wire debug_test_out_pin_1,
	output wire debug_test_out_pin_2
);

	assign from_mon = 0;
	
	wire [39:0] data;
	wire data_recv;
	wire debug_test_out_1;
	wire debug_test_out_2;
	
	assign debug_test_out_pin_1 = ~debug_test_out_1;
	assign debug_test_out_pin_2 = ~debug_test_out_2;
	
	Receiver receiver(
		mon_clk,
		to_mon,
		data,
		data_recv
	);
	
	DebugDataSender debug_sender(
		mon_clk,
		data_recv,
		data,
		debug_sig_on, // state
		debug_test_out_1,
		debug_test_out_2,
		debug_clk,
		debug_sout
	);
	
	

endmodule
