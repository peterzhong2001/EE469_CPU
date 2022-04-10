// regfile
`timescale 1ps/1ps

module regfile(ReadData1, ReadData2, WriteData, ReadRegister1, ReadRegister2, WriteRegister, RegWrite, clk);
	output [63:0] ReadData1, ReadData2;
	input [63:0] WriteData;
	input [4:0] ReadRegister1, ReadRegister2, WriteRegister;
	input RegWrite, clk;
	
	logic reset; // not needed/used
	logic [31:0] decoder_write_out;
	logic [30:0] RegWriteEn;
	logic [31:0][63:0] RegisterOut;
	
	decoder_5_32 decoder0(.decoder_out(decoder_write_out), .decoder_in(WriteRegister)); // decodes input

	assign RegisterOut[31] = 64'b0; // hardwire register 31 to 0
	
	generate
		for(genvar i=0; i<31; i++) begin : each_reg0 // create registers 0-30
			and #50 and0(RegWriteEn[i], decoder_write_out[i], RegWrite);
			D_FF_en #(.WIDTH(64)) registers (.q(RegisterOut[i]), .d(WriteData), .reset(reset), .clk(clk), .en(RegWriteEn[i]));
		end
	endgenerate
	
	mux32_1 #(.WIDTH(64)) mux0(.mux_out(ReadData1), .mux_in(RegisterOut), .sel(ReadRegister1)); // selects ReadRegister1 output
	mux32_1 #(.WIDTH(64)) mux1(.mux_out(ReadData2), .mux_in(RegisterOut), .sel(ReadRegister2)); // selects ReadRegister2 output

endmodule