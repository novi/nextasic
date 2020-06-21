module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon,
	
	input wire debug_clk,
	output wire debug_sout,
	output wire debug_sig_on // state
);

	assign from_mon = 0;
	
	wire [39:0] data;
	wire data_recv;
	
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
		mon_clk,
		debug_sout
	);
	
	

endmodule
