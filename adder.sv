`timescale 1ps/1ps
// Dedicated Adder

module adder (A, B, result);
	input  [63:0] A, B;
	output [63:0] result;
	
	// one extra bit on the carry bus for carry in
	logic [64:0] carry_bus;
	assign carry_bus[0] = 0;
	
	// generate all the full adders
	generate
		for(genvar i=0; i<64; i++) begin : gen_fa
			full_adder fa0 (.A(A[i]), .B(B[i]), .Cin(carry_bus[i]), .S(result[i]), .Cout(carry_bus[i+1]));
		end
	endgenerate
	
endmodule
