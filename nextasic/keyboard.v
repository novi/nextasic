`default_nettype none

module Keyboard(
	input wire clk, // mon clk
	output wire data_ready,
	output wire is_mouse_data, // 0 is keyboard data
	output wire [15:0] keyboard_data, // or mouse data
	input wire keyboard_data_retrieved,
	input wire from_kb,
	output wire to_kb,
);




endmodule

