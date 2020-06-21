module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	input wire dummy_clk,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on, // state
	output wire debug_in_state
);

	assign from_mon = 0;
	
	wire [39:0] data;
	wire data_recv;
	wire in_state;
	
	assign debug_in_state = ~in_state;
	
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
		in_state,
		debug_clk,
		debug_sout
	);
	
	

endmodule
