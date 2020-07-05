module OpDecoder(
	input [7:0] op,
	output reg is_audio_sample,
	output reg audio_starts
);

	always@ (*) begin
		is_audio_sample = 0;
		audio_starts = 0;
		case (op)
			8'h1f: begin
				audio_starts = 1;
			end
			8'h0f: begin
				audio_starts = 1;
			end
			8'hc7: begin
				is_audio_sample = 1;
			end
		endcase
	end

endmodule
