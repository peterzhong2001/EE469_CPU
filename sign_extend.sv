`timescale 1ps/1ps

module sign_extend #(parameter WIDTH_I, WIDTH_O) (signex, value, result);
	input [WIDTH_I-1:0] value;
	input signex; // 1 to sign extend MSB, 0 to Zero extend
	output [WIDTH_O-1:0] result;

	assign result[WIDTH_I-1:0] = value;

	generate
		for(genvar i=WIDTH_I; i<WIDTH_O; i++) begin : each_bit
			assign result[i] = (signex) ? value[WIDTH_I-1] : 1'b0;
		end
	endgenerate

endmodule

module sign_extend_testbench();
	logic signex;
	logic [7:0] value;
	logic [63:0] result;

	sign_extend #(.WIDTH_I(26), .WIDTH_O(64)) dut (.signex, .value, .result);

	initial begin
		signex = 1'b1; value = 8'b01111111; #1000; // Test sign extend 0
		signex = 1'b1; value = 8'b10000001; #1000; // Test sign extend 1
		signex = 1'b0; value = 8'b01111111; #1000; // Test zero extend 0
		signex = 1'b0; value = 8'b10000001; #1000; // Test zero extend 1
	end
endmodule
