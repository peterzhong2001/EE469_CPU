`timescale 1ps/1ps

module addsub_64 (A, B, Sub, carry_out, S, overflow);
	input  [63:0] A, B;
	input         Sub;
	output [63:0] S;
	output        carry_out, overflow;
	
	// create inverted B
	logic [63:0] B_bar;
	genvar i;
	generate
		for(i=0; i<64; i++) begin : invert_B
			not #50 not0 (B_bar[i], B[i]);
		end
	endgenerate
	
	// create 2 to 1 muxes to select B
	logic [1:0][63:0] B_unsel;
	assign B_unsel[1] = B_bar;
	assign B_unsel[0] = B;
	logic [63:0] B_op;
	mux2_1 #(.WIDTH(64)) mux0 (.mux_in(B_unsel), .mux_out(B_op), .sel(Sub));
	
	// one extra bit on the carry bus for carry in
	logic [64:0] carry_bus;
	assign carry_bus[0] = Sub;
	
	// generate all the full adders
	generate
		for(i=0; i<64; i++) begin : gen_fa
			full_adder fa0 (.A(A[i]), .B(B_op[i]), .Cin(carry_bus[i]), .S(S[i]), .Cout(carry_bus[i+1]));
		end
	endgenerate
	
	assign carry_out = carry_bus[64];
	
	// overflow flag
	xor #50 xor0 (overflow, carry_bus[64], carry_bus[63]);
	
endmodule 


module addsub_64_testbench();
	logic [63:0] A, B;
	logic        Sub;
	logic [63:0] S;
	logic        carry_out, overflow;
	
	addsub_64 dut (.*);
	
	initial begin
		// addition, no overflow
	   Sub = 1'b0; A = 64'd4321; B = 64'd5678; #10000;
		// addition, overflow
		Sub = 1'b0; A = 64'd9223372036854775807; B = 64'd1; #10000;
		// subtraction, no overflow
		Sub = 1'b1; A = 64'd5678; B = 64'd1234; #10000;
		// subtraction, overflow
		Sub = 1'b1; A = 64'd9223372036854775808; B = 64'd1; #10000;
	end
endmodule