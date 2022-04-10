`timescale 1ps/1ps

module D_FF (q, d, reset, clk);
	output reg q;
	input d, reset, clk;
	
	always_ff @(posedge clk)
	if (reset)
		q <= 0; // On reset, set to 0
	else
		q <= d; // Otherwise out = d
endmodule

module D_FF_testbench();
	parameter ClockDelay = 1000;

	logic q;
	logic d, reset, clk;
	
	D_FF dut (.q, .d, .reset, .clk);
	
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	initial begin
		reset <= 1; // Test if reset works from start
		@(posedge clk);
		
		reset <= 0;
		d <= 1; // Test if Q will go high from D input
		@(posedge clk);
		
		d <= 0; // Test if Q will go low from D input
		@(posedge clk);
		
		d <= 1; // Setup for reset
		@(posedge clk);
		
		reset <= 1; // Test if reset will make output low
		@(posedge clk);
		
		@(posedge clk);
		
		$stop;
	end
endmodule