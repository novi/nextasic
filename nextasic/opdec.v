`default_nettype none

module OpDecoder(
	input [15:0] op,
	input wire op_valid,
	output reg is_audio_sample,
	output reg audio_starts,
	output reg all_1_packet, // can be used for entire reset
	output reg power_on_packet_R1
);

	always@ (*) begin
		is_audio_sample = 0;
		audio_starts = 0;
		all_1_packet = 0;
		power_on_packet_R1 = 0;
		if (op_valid)
			casex (op)
				16'h1f??: begin // 22khz
					audio_starts = 1;
				end
				16'h0f??: begin // 44khz
					audio_starts = 1;
				end
				16'hc7??: begin
					is_audio_sample = 1;
				end
				16'hff??: begin
					all_1_packet = 1;
				end
				16'hc5ef: begin
					power_on_packet_R1 = 1;
				end
				default: begin
				end
			endcase
	end

endmodule
