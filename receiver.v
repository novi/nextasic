`define READY 1'b0 // define state
`define READ 1'b1

module Receiver(
	input wire clk,
	input wire si, // serial in
	output reg [39:0] data = 0, // 10bytes(40bits)
	output reg data_recv = 0
);

	reg state = `READY;
	integer count = 0;
	
	always@ (posedge clk) begin
		data_recv <= 0;
		case (state)
			`READY : if (si == 1) state <= `READ;
			`READ :
				if (count == 40)
					begin
						state <= `READY;
						count <= 0;
						data_recv <= 1;
					end
				else
					begin
						data[39:0] <= {data[38:0], si};
						count <= count + 1;
					end
		endcase
	end


endmodule


`timescale 1ns/1ns

module test_Receiver;

	reg clk = 0;
	reg sin;
	wire [39:0] data;

	parameter CLOCK = 100;

	Receiver receiver(
		clk,
		sin,
		data
	);
	
	always #(CLOCK/2) clk = ~clk;

	initial begin
		#(CLOCK/4) sin = 0; // initial 
		
		#CLOCK sin = 1; // first, will be dropped
		
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 1;
		#CLOCK sin = 1;
		#CLOCK sin = 1;
		
		#CLOCK sin = 0; 
		#CLOCK sin = 0;
		#CLOCK sin = 0;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 1;
		#CLOCK sin = 0;
		
		#CLOCK sin = 1; 
		#CLOCK sin = 0;
		#CLOCK sin = 0;
		#CLOCK sin = 1; // last bit
		
		
		#CLOCK sin = 0; // normal state
		#CLOCK;
		#CLOCK;
		#CLOCK;
		#CLOCK $stop;
	
	end

endmodule

