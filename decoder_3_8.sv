`timescale 1ps/1ps

module decoder_3_8(decoder_out, decoder_in);
	output [7:0] decoder_out;
	input [2:0] decoder_in;
	
	logic [2:0] not_decoder_in;
	
	not #50 not0(not_decoder_in[0], decoder_in[0]);
	not #50 not1(not_decoder_in[1], decoder_in[1]);
	not #50 not2(not_decoder_in[2], decoder_in[2]);
	
	and #50 and0(decoder_out[0], not_decoder_in[2], not_decoder_in[1], not_decoder_in[0]);
	and #50 and1(decoder_out[1], not_decoder_in[2], not_decoder_in[1], decoder_in[0]);
	and #50 and2(decoder_out[2], not_decoder_in[2], decoder_in[1], not_decoder_in[0]);
	and #50 and3(decoder_out[3], not_decoder_in[2], decoder_in[1], decoder_in[0]);
	and #50 and4(decoder_out[4], decoder_in[2], not_decoder_in[1], not_decoder_in[0]);
	and #50 and5(decoder_out[5], decoder_in[2], not_decoder_in[1], decoder_in[0]);
	and #50 and6(decoder_out[6], decoder_in[2], decoder_in[1], not_decoder_in[0]);
	and #50 and7(decoder_out[7], decoder_in[2], decoder_in[1], decoder_in[0]);
	
endmodule

module decoder_3_8_testbench();
	logic [7:0] decoder_out;
	logic [2:0] decoder_in;
	
	decoder_3_8 dut (.decoder_out, .decoder_in);
	
	initial begin // Test all input variations
		for(integer i=0; i<8; i++) begin
			decoder_in[2:0] = i; #1000;
			assert(decoder_out[i] == 1);
		end
	end
endmodule