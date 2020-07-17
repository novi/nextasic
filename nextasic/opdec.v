`default_nettype none

module OpDecoder(
	input wire [23:0] op, // 3 bytes
	input wire op_valid,
	output reg is_audio_sample,
	output reg audio_starts,
	output reg audio_22khz,
	output reg end_audio_sample,
	output reg all_1_packet, // can be used for entire reset
	output reg power_on_packet_R1,
	output reg keyboard_led_update,
	output reg attenuation_data_valid,
	output reg [7:0] attenuation_data
);

	wire [7:0] data1;
	wire [7:0] data2;
	assign data1 = op[15:8];
	assign data2 = op[7:0];

	always@ (*) begin
		is_audio_sample = 0;
		audio_starts = 0;
		all_1_packet = 0;
		power_on_packet_R1 = 0;
		keyboard_led_update = 0;
		audio_22khz = 0;
		end_audio_sample = 0;
		attenuation_data_valid = 0;
		attenuation_data = 8'hxx;
		if (op_valid)
			casex (op)
				24'hc5ef??: begin
					power_on_packet_R1 = 1;
				end
				24'hc500??: begin
					keyboard_led_update = 1;
				end
				24'hc4????: if (data2 == 0) begin
					attenuation_data_valid = 1;
					attenuation_data = data1;
				end
				24'h1f????: begin // 22khz
					audio_starts = 1;
					audio_22khz = 1;
				end
				24'h0f????: begin // 44khz
					audio_starts = 1;
				end
				24'h17????: begin // 22khz
					end_audio_sample = 1;
					audio_22khz = 1;
				end
				24'h07????: begin // 44khz
					end_audio_sample = 1;
				end
				24'hc7????: begin
					is_audio_sample = 1;
				end
				24'hff????: begin
					all_1_packet = 1;
				end
				default: begin
				end
			endcase
	end

endmodule
