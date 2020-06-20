module nextasic(
	input wire mon_clk,
	input wire to_mon,
	output wire from_mon
);

	assign from_mon = to_mon;

endmodule
