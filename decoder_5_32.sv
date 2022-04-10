`timescale 1ps/1ps

module decoder_5_32(decoder_out, decoder_in);
	output [31:0] decoder_out;
	input [4:0] decoder_in;
	
	logic [4:0] not_decoder_in;
	logic [3:0][7:0] out_3_8;
	logic [3:0] out_2_4;
	
	decoder_2_4 decoder0(.decoder_out(out_2_4), .decoder_in(decoder_in[4:3]));
	
	generate
		for(genvar i=0; i<4; i++) begin : each_decoder_3_8
			decoder_3_8 decoder1(.decoder_out(out_3_8[i]), .decoder_in(decoder_in[2:0]));
		end
	endgenerate

	generate // 2_4 decoder output used with 3_8 decoders
		for(genvar i=0; i<4; i++) begin : each_2_4
			for(genvar j=0; j<8; j++) begin : each_3_8
				and #50 and0(decoder_out[i*8+j], out_2_4[i], out_3_8[i][j]);
			end
		end
	endgenerate
	
endmodule

module decoder_5_32_testbench();
	logic [31:0] decoder_out;
	logic [4:0] decoder_in;
	
	decoder_5_32 dut (.decoder_out, .decoder_in);
	
	initial begin // Test all input variations
		for(integer i=0; i<32; i++) begin
			decoder_in[4:0] = i; #1000;
			assert(decoder_out[i] == 1);
		end
	end
endmodule