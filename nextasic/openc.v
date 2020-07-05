module OpEncoder(
	input wire audio_sample_request,
	output reg [39:0] data,
	output reg data_valid
);

	always@ (*) begin
		if (audio_sample_request) begin
			data = 40'h0700000000;
			data_valid = 1;
		end else begin
			data = 0;
			data_valid = 0;
		end
	end

endmodule
