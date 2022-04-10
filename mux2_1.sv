`timescale 1ps/1ps

module mux2_1 #(parameter WIDTH) (mux_out, mux_in, sel);
	output [WIDTH-1:0] mux_out;
	input [1:0][WIDTH-1:0] mux_in;
	input sel;
	
	logic [1:0][WIDTH-1:0] nand_out;
	logic not_out;
	
	not #50 not0(not_sel, sel);
	
	generate
		for(genvar i=0; i<WIDTH; i++) begin : each_bit // feeds 2 2-input nand gates into 1 2-input nand gate
			nand #50 nand0(nand_out[0][i], not_sel, mux_in[0][i]);
			nand #50 nand1(nand_out[1][i], sel, mux_in[1][i]);
			nand #50 nand2(mux_out[i], nand_out[0][i], nand_out[1][i]);
		end
	endgenerate
	
endmodule

module mux2_1_testbench();
	logic [1:0] mux_in;
	logic sel;
	logic mux_out;
	
	mux2_1 #(.WIDTH(1)) dut (.mux_out, .mux_in, .sel);

	initial begin // Test all input variations
		sel=0; mux_in[0]=0; mux_in[1]=0; #1000;
		sel=0; mux_in[0]=0; mux_in[1]=1; #1000;
		sel=0; mux_in[0]=1; mux_in[1]=0; #1000;
		sel=0; mux_in[0]=1; mux_in[1]=1; #1000;
		sel=1; mux_in[0]=0; mux_in[1]=0; #1000;
		sel=1; mux_in[0]=0; mux_in[1]=1; #1000;
		sel=1; mux_in[0]=1; mux_in[1]=0; #1000;
		sel=1; mux_in[0]=1; mux_in[1]=1; #1000;
	end
endmodule