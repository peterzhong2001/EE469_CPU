`timescale 1ps/1ps

module decoder_2_4(decoder_out, decoder_in);
	output [3:0] decoder_out;
	input [1:0] decoder_in;
	
	logic [1:0] not_decoder_in;
	
	not not0(not_decoder_in[0], decoder_in[0]);
	not not1(not_decoder_in[1], decoder_in[1]);
	
	and #50 and0(decoder_out[0], not_decoder_in[1], not_decoder_in[0]);
	and #50 and1(decoder_out[1], not_decoder_in[1], decoder_in[0]);
	and #50 and2(decoder_out[2], decoder_in[1], not_decoder_in[0]);
	and #50 and3(decoder_out[3], decoder_in[1], decoder_in[0]);
	
endmodule

module decoder_2_4_testbench();
	logic [3:0] decoder_out;
	logic [1:0] decoder_in;
	
	decoder_2_4 dut (.decoder_out, .decoder_in);
	
	initial begin // Test all input variations
		for(integer i=0; i<4; i++) begin
			decoder_in[1:0] = i; #1000;
			assert(decoder_out[i] == 1);
		end
	end
endmodule