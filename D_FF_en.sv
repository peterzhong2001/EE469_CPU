`timescale 1ps/1ps

module D_FF_en #(parameter WIDTH) (q, d, reset, clk, en);
	output [WIDTH-1:0] q;
	input [WIDTH-1:0] d;
	input clk, reset, en;
	
	logic [WIDTH-1:0] mux_out;
	
	generate
		for(genvar i=0; i<WIDTH; i++) begin : each_d_ff_en
			mux2_1 #(.WIDTH(1)) mux0 (.mux_out(mux_out[i]), .mux_in({d[i], q[i]}), .sel(en)); // mux selects new d input when en == 1, otherwise, uses old register value
			D_FF d_ff0 (.q(q[i]), .d(mux_out[i]), .reset(reset), .clk(clk));
		end
	endgenerate
	
endmodule

module D_FF_en_testbench();
	parameter ClockDelay = 1000;
	
	logic [63:0] q, d;
	logic reset, clk, en;
	
	D_FF_en #(.WIDTH(64)) dut (.q, .d, .reset, .clk, .en);
	
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end
	
	initial begin
		reset <= 1; // Test if reset works from start
		en <= 0;
		
		@(posedge clk);
		reset <= 0;
		d <= $random; // Give D random 64 bit input
		
		
		@(posedge clk);
		assert(q==0); // Verify Q is low
		
		@(posedge clk);
		en <= 1;
		
		@(posedge clk);
		@(posedge clk);
		
		assert(q==d); // Verify Q equals random D input once EN is 1
		
		$stop;
		
	end
endmodule