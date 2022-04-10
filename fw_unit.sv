`timescale 1ps/1ps

module fw_unit (SourceReg, DestReg1, DestReg2, WrEn1, WrEn2, Fw_SourceReg);
	input  logic [4:0] SourceReg, DestReg1, DestReg2;
	input  logic       WrEn1, WrEn2;
	output logic [1:0] Fw_SourceReg;                        // 00 if no forwarding, 01/11 if 1 cycle, 10 if 2 cycle. Used for mux selection
                                                            // if both DestReg are equal to the source reg, use the most recent result

	assign Fw_SourceReg[0] = (SourceReg == DestReg1) && WrEn1 && (DestReg1 != 5'h1F);
	assign Fw_SourceReg[1] = (SourceReg == DestReg2) && WrEn2 && (DestReg2 != 5'h1F);
endmodule

module fw_unit_testbench();
	logic [4:0] SourceReg, DestReg1, DestReg2;
	logic       WrEn1, WrEn2;
	logic [1:0] Fw_SourceReg;

	fw_unit dut (.*);

	initial begin
		// test no write enable
		SourceReg = 5'h15; DestReg1 = 5'h15; DestReg2 = 5'h15; WrEn1 = 1'b0; WrEn2 = 1'b0; #250;
		// test x31
		SourceReg = 5'h1F; DestReg1 = 5'h1F; DestReg2 = 5'h00; WrEn1 = 1'b1; WrEn2 = 1'b1; #250;
		SourceReg = 5'h1F; DestReg1 = 5'h00; DestReg2 = 5'h1F; WrEn1 = 1'b1; WrEn2 = 1'b1; #250;
		// test SourceReg == DestReg1
		SourceReg = 5'h15; DestReg1 = 5'h15; DestReg2 = 5'h00; WrEn1 = 1'b1; WrEn2 = 1'b1; #250;
		// test SourceReg == DestReg2
		SourceReg = 5'h15; DestReg1 = 5'h00; DestReg2 = 5'h15; WrEn1 = 1'b1; WrEn2 = 1'b1; #250;
		// test if both are equal to DestReg
		SourceReg = 5'h15; DestReg1 = 5'h15; DestReg2 = 5'h15; WrEn1 = 1'b1; WrEn2 = 1'b1; #250;
	end
endmodule