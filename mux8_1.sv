`timescale 1ps/1ps

module mux8_1 #(parameter WIDTH) (mux_out, mux_in, sel);
	output [WIDTH-1:0] mux_out;
	input [7:0][WIDTH-1:0] mux_in;
	input [2:0] sel;
	
	logic [2:0] sel_bar;
	logic [7:0][WIDTH-1:0] and_out;
	logic [2:0][WIDTH-1:0] or_out;
	
	genvar i;
	generate
		for(i=0; i<3; i++) begin : each_sel
			not not0(sel_bar[i], sel[i]);
		end
	endgenerate
	
	generate
		for(i=0; i<WIDTH; i++) begin : each_bit
			and #50 and7 (and_out[7][i], mux_in[7][i], sel[2], sel[1], sel[0]);
			and #50 and6 (and_out[6][i], mux_in[6][i], sel[2], sel[1], sel_bar[0]);
			and #50 and5 (and_out[5][i], mux_in[5][i], sel[2], sel_bar[1], sel[0]);
			and #50 and4 (and_out[4][i], mux_in[4][i], sel[2], sel_bar[1], sel_bar[0]);
			and #50 and3 (and_out[3][i], mux_in[3][i], sel_bar[2], sel[1], sel[0]);
			and #50 and2 (and_out[2][i], mux_in[2][i], sel_bar[2], sel[1], sel_bar[0]);
			and #50 and1 (and_out[1][i], mux_in[1][i], sel_bar[2], sel_bar[1], sel[0]);
			and #50 and0 (and_out[0][i], mux_in[0][i], sel_bar[2], sel_bar[1], sel_bar[0]);
			
			or #50 or0 (or_out[1][i], and_out[7][i], and_out[6][i], and_out[5][i], and_out[4][i]);
			or #50 or1 (or_out[0][i], and_out[3][i], and_out[2][i], and_out[1][i], and_out[0][i]);
			or #50 or2 (mux_out[i], or_out[1][i], or_out[0][i]);
		end
	endgenerate
	
endmodule

module mux8_1_testbench();
	logic [7:0][63:0] mux_in;
	logic [2:0] sel;
	logic [63:0] mux_out;
	
	mux8_1 #(.WIDTH(64)) dut (.mux_out, .mux_in, .sel);
	
	initial begin
		for(integer i=0; i<8; i++) begin
			mux_in[i] = $random; // Assign a random 64 bit value to each mux input
		end
		
		#1000
		
		for(integer i=0; i<8; i++) begin  // Verify each mux input can be selected
			sel[2:0] = i; #1000;
			assert(mux_out == mux_in[i]); #1000;
		end
	end
endmodule