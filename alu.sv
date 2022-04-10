`timescale 1ps/1ps
// Meaning of signals in and out of the ALU:

// Flags:
// negative: whether the result output is negative if interpreted as 2's comp.
// zero: whether the result output was a 64-bit zero.
// overflow: on an add or subtract, whether the computation overflowed if the inputs are interpreted as 2's comp.
// carry_out: on an add or subtract, whether the computation produced a carry-out.

// cntrl			Operation						Notes:
// 000:			result = B						value of overflow and carry_out unimportant
// 010:			result = A + B
// 011:			result = A - B
// 100:			result = bitwise A & B		value of overflow and carry_out unimportant
// 101:			result = bitwise A | B		value of overflow and carry_out unimportant
// 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant

module alu(A, B, cntrl, result, negative, zero, overflow, carry_out);
	input [63:0] A, B;
	input [2:0] cntrl;
	output [63:0] result;
	output negative, zero, overflow, carry_out;

	logic [7:0][63:0] result_unselected;

	// 64-bit adder/subtractor, using cntrl[0] as the sub signal
	addsub_64 addsub0(.A, .B, .Sub(cntrl[0]), .carry_out, .overflow, .S(result_unselected[2]));

	// pass operation
	assign result_unselected[0] = B;
	// sel = 1 is an invalid select signal
	assign result_unselected[1] = '0;
	// add and sub both uses the output from the addsub_64 module
	assign result_unselected[3] = result_unselected[2];

	// negative flag
	assign negative = result[63];

	// zero flag
	logic [15:0] nor_out;
	logic [3:0] and_out;
	genvar i;
	generate
		for(i=0; i<16; i++) begin : each_nor
			nor #50 nor0(nor_out[i], result[i*4], result[i*4+1], result[i*4+2], result[i*4+3]);
		end
		for(i=0; i<4; i++) begin : each_or
			and #50 and0(and_out[i], nor_out[i*4], nor_out[i*4+1], nor_out[i*4+2], nor_out[i*4+3]);
		end
	endgenerate
	and #50 and1(zero, and_out[0], and_out[1], and_out[2], and_out[3]);

	// bitwise operations
	generate
		for(i=0; i<64; i++) begin : each_bit
			and #50 and0(result_unselected[4][i], A[i], B[i]);
			or #50 or0(result_unselected[5][i], A[i], B[i]);
			xor #50 xor0(result_unselected[6][i], A[i], B[i]);
		end
	endgenerate

	mux8_1 #(.WIDTH(64)) mux0(.mux_out(result), .mux_in(result_unselected), .sel(cntrl));

endmodule