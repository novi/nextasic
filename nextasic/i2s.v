module I2SSender(
	input wire in_clk,
	input wire in_valid,
	input wire [31:0] in_data,
	input wire i2s_clk,
	output wire lrck,
	output wire bck, // ~2.8Mhz
	output reg sout = 0 // i2s data, serial out
);

	localparam IN_SAMPLES_L = 1'b0;
	localparam IN_SAMPLES_R = 1'b1;
	
	assign bck = i2s_clk;
	

	reg state = IN_SAMPLES_R;
	reg data1_filled = 0;
	reg data1_filled_ack = 0;
	reg data2_valid = 0;
	reg can_serial_out = 0;
	reg [31:0] data1;
	reg [31:0] data2;
	reg [5:0] counter = 0; // 0 to 63
	
	assign lrck = state;
	
	always@ (negedge bck) begin
		if (counter == 31) begin
			case (state)
				IN_SAMPLES_R: begin
					state <= IN_SAMPLES_L;
					can_serial_out <= data2_valid;
				end
				IN_SAMPLES_L: state <= IN_SAMPLES_R;
			endcase
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
		
		if (!data1_filled)
			data1_filled_ack <= 0;
			
		if (can_serial_out && counter <= 15) begin
			sout <= data2[31];
			data2[31:1] <= data2[30:0];
			data2[0] <= 0;
			data2_valid <= 0;
		end else begin
			sout <= 0;
			if (state == IN_SAMPLES_R && !data2_valid) begin
				if (data1_filled) begin
					data2 <= data1;
					data2_valid <= 1;
					data1_filled_ack <= 1;
				end
			end
			
		end
	end
	
	always@ (posedge in_clk) begin
		if (data1_filled_ack) begin
			data1_filled <= 0; // TODO: request next sound samples
		end
		if (in_valid && !data1_filled) begin
			data1 <= in_data;
			data1_filled <= 1;
		end
	end



endmodule


module test_I2SSender;

	reg in_clk = 0;
	reg out_clk = 0;
	reg [31:0] data;
	reg in_valid = 0;
	wire lrck;
	wire bck;
	wire sout;

	
	parameter OUT_CLOCK = (100*4);
	parameter IN_CLOCK = 200;

	I2SSender sender(
		in_clk,
		in_valid,
		data,
		out_clk,
		lrck,
		bck,
		sout
	);
	
	always #(IN_CLOCK/2) in_clk = ~in_clk;
	always #(OUT_CLOCK/2) out_clk = ~out_clk;

	initial begin
		in_valid = 0;
		data = 32'b11011001100110011001100110010001;
		#(OUT_CLOCK*35);
		
		#(IN_CLOCK);
		in_valid = 1;
		#(IN_CLOCK);
		in_valid = 0;
		#(OUT_CLOCK*32+5)
		data = 32'b10011001100110011001100110010011;
		#(IN_CLOCK);
		in_valid = 1;
		#(IN_CLOCK);
		in_valid = 0;
		
		#(OUT_CLOCK*64*3);
		#(OUT_CLOCK*20);
		
		$stop;
	end
	
endmodule


