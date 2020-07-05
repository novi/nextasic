module OpDecoder(
	input [7:0] op,
	output reg is_audio_sample,
	output reg audio_starts
);

	always@ (*) begin
		case (op)
			8'h1f: audio_starts = 1;
			8'h0f: audio_starts = 1;
			8'hc7: is_audio_sample = 1;
			default: begin
				is_audio_sample = 0;
				audio_starts = 0;
			end
		endcase
	end

endmodule
