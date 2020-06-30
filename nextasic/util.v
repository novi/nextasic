module FF2SyncP(
	input wire in,
	input wire out_clk,
	output wire out_data
);

	reg f1, f2;
	
	assign out_data = f2;
	
	always@ (posedge out_clk) begin
		f1 <= in;
		f2 <= f1;
	end
	

endmodule

module FF2SyncN(
	input wire in,
	input wire out_clk,
	output wire out_data
);

	reg f1, f2;
	
	assign out_data = f2;
	
	always@ (negedge out_clk) begin
		f1 <= in;
		f2 <= f1;
	end
	

endmodule
