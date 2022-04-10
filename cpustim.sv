// Test bench for CPU
`timescale 1ns/10ps

module cpustim();

	parameter ClockDelay = 20;

	logic		clk, rst;

	pipelined_cpu dut (.clk, .rst);

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	integer i;
	logic [63:0] test_val;
	initial begin
		rst <= 1;              @(posedge clk);
		rst <= 0; repeat(2000)  @(posedge clk);
		$stop;
	end
endmodule
