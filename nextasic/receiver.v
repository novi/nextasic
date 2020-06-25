module Receiver(
	input wire clk,
	input wire si, // serial in
	output reg [39:0] data = 0, // 10bytes(40bits)
	output reg data_recv_valid = 0
);
	
	localparam READY = 1'b0; // define state
	localparam READ = 1'b1;

	reg state = READY;
	reg unsigned [5:0] count = 0; // range 0 to 40
	
	always@ (negedge clk) begin
		if (count == 40)
			data_recv_valid <= 1;
		if (count == 41)
			data_recv_valid <= 0;
	end
	
	always@ (posedge clk) begin
		case (state)
			READY : if (si == 1) state <= READ;
			READ :
				case (count)
					41: begin
						state <= READY;
						count <= 0;
					end
					40: begin
						count <= count + 1'b1;
					end
					default: begin
						data[39:0] <= {si, data[39:1]};
						count <= count + 1'b1;
					end
				endcase
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
		
		#CLOCK sin = 0;
		
		#(CLOCK*5);
		
		
		#CLOCK $stop;
		
		// TODO: check output
	
	end

endmodule

