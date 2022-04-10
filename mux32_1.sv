`timescale 1ps/1ps

module mux32_1 #(parameter WIDTH) (mux_out, mux_in, sel);
	output [WIDTH-1:0] mux_out;
	input [31:0][WIDTH-1:0] mux_in;
	input [4:0] sel;
	
	logic [7:0][WIDTH-1:0] mux4_out;
	logic [1:0][WIDTH-1:0] mux2_in;

	generate // feeds 8 4_1 muxes into 2 4_1 muxes to create 2 16_1 muxes
		for(genvar i=0; i<2; i++) begin : each_16_1 // second stage 4_1 muxes uses sel[3:2]
			for(genvar j=0; j<4; j++) begin: each_4_1 // first stage 4_1 muxes uses sel[1:0]
				mux4_1 #(.WIDTH(WIDTH)) mux0(.mux_out(mux4_out[i*4+j]), .mux_in(mux_in[3+j*4+i*16:j*4+i*16]), .sel(sel[1:0])); // index pattern is (mux_in[3:0], mux4_out[0]), (mux_in[7:4], mux4_out[2]), etc.
			end
			
			mux4_1 #(.WIDTH(WIDTH)) mux1(.mux_out(mux2_in[i]), .mux_in(mux4_out[3+i*4:i*4]), .sel(sel[3:2])); // index pattern is (mux4_out[3:0], mux2_in[0]), (mux4_out[7:4], mux2_in[1])
			
		end
	endgenerate
	
	mux2_1 #(.WIDTH(WIDTH)) mux2(.mux_out(mux_out), .mux_in(mux2_in), .sel(sel[4])); // feeds 2 4_1 muxes into a 2_1 mux
	
endmodule

module mux32_1_testbench();
	logic [31:0][63:0] mux_in;
	logic [4:0] sel;
	logic [63:0] mux_out;
	
	mux32_1 #(.WIDTH(64)) dut (.mux_out, .mux_in, .sel);
	
	initial begin
		for(integer i=0; i<32; i++) begin
			mux_in[i] = $random; // Assign a random 64 bit value to each mux input
		end
		
		#1000
		
		for(integer i=0; i<32; i++) begin  // Verify each mux input can be selected
			sel[4:0] = i; #1000;
			assert(mux_out == mux_in[i]); #1000;
		end
	end
endmodule