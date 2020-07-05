module I2SSender(
	input wire in_clk,
	input wire in_valid,
	input wire [31:0] in_data,
	input wire audio_start_in,
	output wire audio_req_out_, // request next sound samples to NeXT hardware
	//input wire i2s_clk, // 22.5792Mhz(or 11.2896Mhz)
	input wire bck, // 2.8224Mhz, 64fs
	output wire lrck, // 1fs=44.1khz	
	output reg sout = 0 // i2s data, serial out
);

	localparam IN_SAMPLES_L = 1'b0;
	localparam IN_SAMPLES_R = 1'b1;
	localparam REQ_DELAY = 2;

	reg state = IN_SAMPLES_R;
	reg data1_filled = 0;
	FF2SyncN data1_filled__(data1_filled, bck, data1_filled_);
	reg data1_retrieved = 0;
	FF2SyncP data1_retrieved__(data1_retrieved, in_clk, data1_retrieved_);
	reg data2_valid = 0; // data2 has complete sample data not during shifting
	reg can_serial_out = 0;
	reg [31:0] data1;
	reg [31:0] data2;
	reg [5:0] counter = 0; // 0 to 63
	reg audio_req = 0; // bck domain
	FF2SyncN audio_req__(audio_req, in_clk, audio_req_);
	reg audio_req_ack = 0; // in_clk domain
	FF2SyncN audio_req_ack__(audio_req_ack, bck, audio_req_ack_);
	reg audio_start = 0; // in_clk domain
	FF2SyncN audio_start__(audio_start, bck, audio_start_);
	reg audio_start_ack = 0; // bck domain
	FF2SyncP audio_start_ack__(audio_start_ack, in_clk, audio_start_ack_);
	reg [4:0] req_counter = 0;
	reg audio_req_out = 0;
	reg [REQ_DELAY:0] audio_req_out_a = 0;

	assign audio_req_out_ = audio_req_out; //audio_req_out_a[REQ_DELAY];
	assign lrck = state;
	
	always@ (negedge bck) begin
		// request
		if (audio_req_ack_)
			audio_req <= 0;

		if (audio_start_ && !audio_start_ack) begin
			audio_start_ack <= 1;
		end
		
		if (req_counter == 5'd21) begin // TODO: timing
			req_counter <= 0;
			audio_req <= 1;
		end else begin
			req_counter <= req_counter + 1'b1;
		end
	
		// audio data
		if (counter == 31) begin
			case (state)
				IN_SAMPLES_R: begin
					state <= IN_SAMPLES_L;
					can_serial_out <= data2_valid;
					audio_start_ack <= 0;
					audio_req <= 0;
					
				end
				IN_SAMPLES_L: begin
					state <= IN_SAMPLES_R;
					req_counter <= 0;
				end
			endcase
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
		
		if (!data1_filled_)
			data1_retrieved <= 0;
		
		if (state == IN_SAMPLES_L)
			req_counter <= 0;
		
		if (can_serial_out && counter <= 15) begin
			sout <= data2[31];
			data2[31:1] <= data2[30:0];
			data2[0] <= 0;
			data2_valid <= 0; // data2 is partial data, shifing...
		end else begin
			sout <= 0;
			if (state == IN_SAMPLES_R && !data2_valid) begin
				if (data1_filled) begin
					data2 <= data1;
					data2_valid <= 1;
					data1_retrieved <= 1;
				end
			end
		end
	end
	
	always@ (negedge in_clk) begin
		if (!audio_req_ack && audio_req_) begin
			audio_req_out <= 1;
			audio_req_ack <= 1;
		end else if (audio_req_out)
			audio_req_out <= 0;
			
		audio_req_out_a[REQ_DELAY:0] <= {audio_req_out_a[(REQ_DELAY-1):0], audio_req_out}; 
			
		if (!audio_req_)
			audio_req_ack <= 0;
	end
	
	always@ (posedge in_clk) begin
		// request
		if (audio_start_in)
			audio_start <= 1;

		if (audio_start_ack_)
			audio_start <= 0;
		
		// audio data
		if (data1_retrieved_)
			data1_filled <= 0;
						
		if (in_valid && !data1_filled) begin
			data1 <= in_data;
			data1_filled <= 1;
		end
	end



endmodule


`timescale 1ns/1ns


module test_I2SSender;

	reg in_clk = 0;
	reg out_clk = 0; // bck
	reg [31:0] data;
	reg in_valid = 0;
	reg audio_start = 0;
	wire lrck;
	wire sout;
	wire audio_req;

	
	parameter OUT_CLOCK = (100*4);
	parameter IN_CLOCK = 200;

	I2SSender sender(
		in_clk,
		in_valid,
		data,
		audio_start,
		audio_req,
		out_clk, // bck
		lrck,
		sout
	);
	
	always #(IN_CLOCK/2) in_clk = ~in_clk;
	always #(OUT_CLOCK/2) out_clk = ~out_clk;

	initial begin
		in_valid = 0;
		data = 32'b11011001100110011001100110010001;
		#(OUT_CLOCK*35*4);
		
		@(negedge in_clk);
		audio_start = 1;
		@(negedge in_clk);
		audio_start = 0;
		#(OUT_CLOCK*6);
		@(negedge in_clk);
		in_valid = 1;
		@(negedge in_clk);
		in_valid = 0;
		#(OUT_CLOCK*32+5)
		data = 32'b10011001100110011001100110010011;
		@(negedge in_clk);
		in_valid = 1;
		@(negedge in_clk);
		in_valid = 0;
		
		#(OUT_CLOCK*64*10);
		
		$stop;
	end
	
endmodule


