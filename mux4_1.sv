`timescale 1ps/1ps

module mux4_1 #(parameter WIDTH) (mux_out, mux_in, sel);
	output [WIDTH-1:0] mux_out;
	input [3:0][WIDTH-1:0] mux_in;
	input [1:0] sel;
	
	logic [1:0] not_sel;
	logic [3:0][WIDTH-1:0] nand_out;
	
	generate
		for(genvar i=0; i<2; i++) begin : each_sel
			not not0(not_sel[i], sel[i]);
		end
	endgenerate
	
	generate
		for(genvar i=0; i<WIDTH; i++) begin : each_bit // feeds 4 3-input nand gates into 1 4-input nand gate
			nand #50 nand0(nand_out[0][i], mux_in[0][i], not_sel[1], not_sel[0]);
			nand #50 nand1(nand_out[1][i], mux_in[1][i], not_sel[1], sel[0]);
			nand #50 nand2(nand_out[2][i], mux_in[2][i], sel[1], not_sel[0]);
			nand #50 nand3(nand_out[3][i], mux_in[3][i], sel[1], sel[0]);
			nand #50 nand4(mux_out[i], nand_out[3][i], nand_out[2][i], nand_out[1][i], nand_out[0][i]);
		end
	endgenerate
	
endmodule

module mux4_1_testbench();
	logic [3:0] mux_in;
	logic [1:0] sel;
	logic mux_out;
	
	mux4_1 #(.WIDTH(1)) dut (.mux_out, .mux_in, .sel);
	
	initial begin // Test all input variations
		for(integer i=0; i<64; i++) begin
			{sel[1], sel[0], mux_in[0], mux_in[1], mux_in[2], mux_in[3]} = i; #1000;
		end
	end
endmodule