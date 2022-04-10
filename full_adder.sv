`timescale 1ps/1ps

module full_adder (A, B, S, Cin, Cout);
	input  A, B, Cin;
	output S, Cout;
	
	// S = A xor B xor Cin
	xor #50 xor0 (S, A, B, Cin);
	
	// Cout = (A & B) | (B & Cin) | (A & Cin)
	logic and0_out, and1_out, and2_out;
	
	and #50 and0 (and0_out, A, B);
	and #50 and1 (and1_out, B, Cin);
	and #50 and2 (and2_out, A, Cin);
	or #50 or0 (Cout, and0_out, and1_out, and2_out);
endmodule 