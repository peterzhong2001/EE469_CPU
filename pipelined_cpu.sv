`timescale 1ps/1ps
module pipelined_cpu (clk, rst);
	input logic clk, rst;

	parameter
	  BOp=    32'b000101xxxxxxxxxxxxxxxxxxxxxxxxxx
	, BLTOp=  32'b01010100xxxxxxxxxxxxxxxxxxx01011
	, CBZOp=  32'b10110100xxxxxxxxxxxxxxxxxxxxxxxx
	, ADDSOp= 32'b10101011000xxxxxxxxxxxxxxxxxxxxx
	, SUBSOp= 32'b11101011000xxxxxxxxxxxxxxxxxxxxx
	, ANDOp=  32'b10001010000xxxxxxxxxxxxxxxxxxxxx
	, EOROp=  32'b11001010000xxxxxxxxxxxxxxxxxxxxx
	, LSROp=  32'b11010011010xxxxxxxxxxxxxxxxxxxxx
	, ADDIOp= 32'b1001000100xxxxxxxxxxxxxxxxxxxxxx
	, LDUROp= 32'b11111000010xxxxxxxxxxxxxxxxxxxxx
	, STUROp= 32'b11111000000xxxxxxxxxxxxxxxxxxxxx;

	logic [31:0] instr;
	logic [ 1:0][63:0] PC;

	logic [ 4:0] Rd, Rm, Rn;                                                         // Register addresses
	logic [ 5:0] ShAmt;                                                              // Shift amount for R-Type instruction
	logic [ 8:0] DAddr9;                                                             // Addr for D-Type instruction
	logic [11:0] ALUImm12;                                                           // Immediate value for I-type instruction
	logic [18:0] CondAddr19;                                                         // Addr for CB-Type instruction
	logic [25:0] BrAddr26;                                                           // Addr for B-Type instruction

	assign Rd         = instr[ 4: 0];
	assign Rn         = instr[ 9: 5];
	assign Rm         = instr[20:16];
	assign ShAmt      = instr[15:10];
	assign DAddr9     = instr[20:12];
	assign ALUImm12   = instr[21:10];
	assign CondAddr19 = instr[23: 5];
	assign BrAddr26   = instr[25: 0];

	logic Reg2Loc, BrTaken, UncondBr, Imm;                                  // cntrl for Reg/Dec
	logic [ 1:0][ 2:0] ALUOp;                                               // cntrl for ALU (Execute)
	logic [ 1:0] ALUSrc, FlagEn, Shift;                                     // cntrl for Execute
	logic [ 2:0] MemWrite, MemToReg;                                        // cntrl for Mem
	logic [ 3:0] RegWrite;                                                  // cntrl for WB
	logic [12:0] controls;                                                  // Packing all control codes into an array
	assign Reg2Loc       = controls[12];
	assign ALUSrc[0]     = controls[11];
	assign MemToReg[0]   = controls[10];
	assign RegWrite[0]   = controls[9];
	assign MemWrite[0]   = controls[8];
	assign BrTaken       = controls[7];
	assign UncondBr      = controls[6];
	assign ALUOp[0]      = controls[5:3];
	assign Imm           = controls[2];
	assign Shift[0]      = controls[1];
	assign FlagEn[0]     = controls[0];

	//------------------------------------------------------------------------------------------
	// Control Registers
	//------------------------------------------------------------------------------------------
	// Execute Control Registers
	D_FF_en #(.WIDTH(3)) ALUOp_FF0 (.q(ALUOp[1]), .d(ALUOp[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) ALUSrc_FF0 (.q(ALUSrc[1]), .d(ALUSrc[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) FlagEn_FF0 (.q(FlagEn[1]), .d(FlagEn[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) Shift_FF0 (.q(Shift[1]), .d(Shift[0]), .reset(rst), .clk(clk), .en(1'b1));

	// Mem Control Registers
	D_FF_en #(.WIDTH(1)) MemWrite_FF0 (.q(MemWrite[1]), .d(MemWrite[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) MemWrite_FF1 (.q(MemWrite[2]), .d(MemWrite[1]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) MemToReg_FF0 (.q(MemToReg[1]), .d(MemToReg[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) MemToReg_FF1 (.q(MemToReg[2]), .d(MemToReg[1]), .reset(rst), .clk(clk), .en(1'b1));

	// WB Control Registers
	D_FF_en #(.WIDTH(1)) RegWrite_FF0 (.q(RegWrite[1]), .d(RegWrite[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) RegWrite_FF1 (.q(RegWrite[2]), .d(RegWrite[1]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(1)) RegWrite_FF2 (.q(RegWrite[3]), .d(RegWrite[2]), .reset(rst), .clk(clk), .en(1'b1));

	//------------------------------------------------------------------------------------------
	// IF Stage
	//------------------------------------------------------------------------------------------

	// Sign Extend CondAddr19 and BrAddr26
	logic [1:0][63:0] UncondBr_SE;
	sign_extend #(.WIDTH_I(19), .WIDTH_O(64)) Cond_SE(.signex(1'b1), .value(CondAddr19), .result(UncondBr_SE[0]));
	sign_extend #(.WIDTH_I(26), .WIDTH_O(64)) BrAddr_SE(.signex(1'b1), .value(BrAddr26), .result(UncondBr_SE[1]));

	// Select CondAddr19_SE or BrAddr26_SE from UncondBr control
	logic [63:0] UncondBr_Mux;
	mux2_1 #(.WIDTH(64)) UncondBrMux (.mux_out(UncondBr_Mux), .mux_in(UncondBr_SE), .sel(UncondBr));

	// Left shift UncondBr_Mux result by 2
	logic [63:0] UncondBr_Shifted;
	assign UncondBr_Shifted[0] = 1'b0;
	assign UncondBr_Shifted[1] = 1'b0;
	generate
		for(genvar i=2; i<64; i++) begin : each_shift_bit
			assign UncondBr_Shifted[i] = UncondBr_Mux[i-2];
		end
	endgenerate

	logic [1:0][63:0] BrTaken_Add;
	logic      [63:0] PC_delayReg_out; // when branch is taken, use PC from previous cycle (the branch instruction) to compute destination
	D_FF_en #(.WIDTH(64)) PC_delayReg (.q(PC_delayReg_out), .d(PC[1]), .reset(rst), .clk(clk), .en(1'b1));           // delay register for PC
	adder adder_BrTaken1(.A(UncondBr_Shifted), .B(PC_delayReg_out), .result(BrTaken_Add[1]));          // Add UncondBr_Shifted with PC
	adder adder_BrTaken0(.A(PC[1]), .B(64'd4), .result(BrTaken_Add[0]));                               // PC + 4

	// Select next PC address based on BrTaken control
	mux2_1 #(.WIDTH(64)) BrTakenMux (.mux_out(PC[0]), .mux_in(BrTaken_Add), .sel(BrTaken));
	D_FF_en #(.WIDTH(64)) PC_FF (.q(PC[1]), .d(PC[0]), .reset(rst), .clk(clk), .en(1'b1));

	// Pipeline Register for IF/RD
	logic [31:0] IF_out;         // instructions are 32-bit wide
	instructmem IMEM(.address(PC[1]), .instruction(IF_out), .clk(clk)); // Load instruction from instruction memory
	D_FF_en #(.WIDTH(32)) IF_RD_FF (.q(instr), .d(IF_out), .reset(rst), .clk(clk), .en(1'b1));

	//------------------------------------------------------------------------------------------
	// Reg/Dec Stage
	//------------------------------------------------------------------------------------------

	logic [63:0] Reg_WrData, Reg_RdData1, Reg_RdData2, Reg_RdData1_ex, Reg_RdData2_ex;
	logic [ 4:0] Reg_RdAddr1, Reg_RdAddr2;
	logic [ 3:0][ 4:0] Reg_WrAddr;
	logic [ 1:0][ 4:0] Reg2Loc_Mux_in;
	assign Reg_RdAddr1 = Rn;
	assign Reg_WrAddr[0] = Rd;
	assign Reg2Loc_Mux_in[1] = Rm;
	assign Reg2Loc_Mux_in[0] = Rd;

	D_FF_en #(.WIDTH(5)) Reg_WrAddr_FF0 (.q(Reg_WrAddr[1]), .d(Reg_WrAddr[0]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(5)) Reg_WrAddr_FF1 (.q(Reg_WrAddr[2]), .d(Reg_WrAddr[1]), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(5)) Reg_WrAddr_FF2 (.q(Reg_WrAddr[3]), .d(Reg_WrAddr[2]), .reset(rst), .clk(clk), .en(1'b1));

	mux2_1 #(.WIDTH(5)) Reg2Loc_Mux (.mux_out(Reg_RdAddr2), .mux_in(Reg2Loc_Mux_in), .sel(Reg2Loc));

	// inverted clock to be used for the regfile
	logic clk_inv;
	not #50 reg_clk_inv (clk_inv, clk);
	regfile RegFile0 (.ReadData1(Reg_RdData1),
					  .ReadData2(Reg_RdData2),
					  .WriteData(Reg_WrData),
					  .ReadRegister1(Reg_RdAddr1),
					  .ReadRegister2(Reg_RdAddr2),
					  .WriteRegister(Reg_WrAddr[3]),
					  .RegWrite(RegWrite[3]),
					  .clk(clk_inv));

	// Imm Mux
	logic [ 1:0][63:0] Imm_Mux_in;
	logic [ 1:0][63:0] Imm_Mux_out;
	sign_extend #(.WIDTH_I(9), .WIDTH_O(64)) DAddr9_SE(.signex(1'b1), .value(DAddr9), .result(Imm_Mux_in[0]));
	sign_extend #(.WIDTH_I(12), .WIDTH_O(64)) ALUImm12_SE(.signex(1'b0), .value(ALUImm12), .result(Imm_Mux_in[1]));
	mux2_1 #(.WIDTH(64)) Imm_Mux (.mux_out(Imm_Mux_out[0]), .mux_in(Imm_Mux_in), .sel(Imm));
	D_FF_en #(.WIDTH(64)) Imm_FF(.q(Imm_Mux_out[1]), .d(Imm_Mux_out[0]), .reset(rst), .clk(clk), .en(1'b1));

	// Forwarding Units. 1 and 2 for ALU, 3 for branch acceleration
	logic [ 4:0] Rd_ex, Rd_mem;
	logic [1:0] fwSel1, fwSel2;
	D_FF_en #(.WIDTH(5)) Rd_FF0(.q(Rd_ex), .d(Rd), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(5)) Rd_FF1(.q(Rd_mem), .d(Rd_ex), .reset(rst), .clk(clk), .en(1'b1));
	fw_unit fw_unit1 (.SourceReg(Reg_RdAddr1), .DestReg1(Rd_ex), .DestReg2(Rd_mem), .WrEn1(RegWrite[1]), .WrEn2(RegWrite[2]), .Fw_SourceReg(fwSel1));
	fw_unit fw_unit2 (.SourceReg(Reg_RdAddr2), .DestReg1(Rd_ex), .DestReg2(Rd_mem), .WrEn1(RegWrite[1]), .WrEn2(RegWrite[2]), .Fw_SourceReg(fwSel2));

	logic [ 3:0][63:0] fwMux1_in, fwMux2_in;
	logic       [63:0] fwMux1_out, fwMux2_out;
	logic [ 1:0][63:0] EX_out;
	logic       [63:0] MemToRegData;
	assign fwMux1_in[0] = Reg_RdData1;
	assign fwMux1_in[1] = EX_out[0];
	assign fwMux1_in[2] = MemToRegData;
	assign fwMux1_in[3] = EX_out[0];
	assign fwMux2_in[0] = Reg_RdData2;
	assign fwMux2_in[1] = EX_out[0];
	assign fwMux2_in[2] = MemToRegData;
	assign fwMux2_in[3] = EX_out[0];

	mux4_1 #(.WIDTH(64)) fwMux1 (.mux_out(fwMux1_out), .mux_in(fwMux1_in), .sel(fwSel1));
	mux4_1 #(.WIDTH(64)) fwMux2 (.mux_out(fwMux2_out), .mux_in(fwMux2_in), .sel(fwSel2));

	D_FF_en #(.WIDTH(64)) RdData1_FF(.q(Reg_RdData1_ex), .d(fwMux1_out), .reset(rst), .clk(clk), .en(1'b1));
	D_FF_en #(.WIDTH(64)) RdData2_FF(.q(Reg_RdData2_ex), .d(fwMux2_out), .reset(rst), .clk(clk), .en(1'b1));

	// Branch Acceleration
	logic [15:0] nor_out;
	logic [3:0] and_out;
	logic BrZero;
	genvar i;
	generate
		for(i=0; i<16; i++) begin : each_nor
			nor #50 nor0 (nor_out[i], fwMux2_out[i*4], fwMux2_out[i*4+1], fwMux2_out[i*4+2], fwMux2_out[i*4+3]);
		end
		for(i=0; i<4; i++) begin : each_or
			and #50 and0 (and_out[i], nor_out[i*4], nor_out[i*4+1], nor_out[i*4+2], nor_out[i*4+3]);
		end
	endgenerate
	and #50 and1 (BrZero, and_out[0], and_out[1], and_out[2], and_out[3]);

	//------------------------------------------------------------------------------------------
	// Execute Stage
	//------------------------------------------------------------------------------------------

	// shifter
	logic [ 5:0] ShAmt_ex;
	D_FF_en #(.WIDTH(6)) ShAmt_FF0 (.q(ShAmt_ex), .d(ShAmt), .reset(rst), .clk(clk), .en(1'b1));
	logic [63:0] RdDataShift;
	shifter Data1_Shifter (.value(Reg_RdData1_ex),
						   .direction(1'b1),                 // only doing logical right shifts
						   .distance(ShAmt_ex),
						   .result(RdDataShift));

	// ALU
	logic [63:0] ALUSrc_Mux_out, alu_result;
	logic        alu_NF, alu_OF, alu_ZF, alu_Cout;
	alu ALU0 (.A(Reg_RdData1_ex),
			  .B(ALUSrc_Mux_out),
			  .cntrl(ALUOp[1]),
			  .result(alu_result),
			  .negative(alu_NF),
			  .zero(alu_ZF),
			  .overflow(alu_OF),
			  .carry_out(alu_Cout));

	// ALUSrc Mux
	logic [ 1:0][63:0] ALUSrc_Mux_in;
	assign ALUSrc_Mux_in[0] = Reg_RdData2_ex;
	assign ALUSrc_Mux_in[1] = Imm_Mux_out[1];
	mux2_1 #(.WIDTH(64)) ALUSrc_Mux (.mux_out(ALUSrc_Mux_out), .mux_in(ALUSrc_Mux_in), .sel(ALUSrc[1]));

	// shift mux
	logic [ 1:0][63:0] Shift_Mux_in;
	assign Shift_Mux_in[1] = RdDataShift;
	assign Shift_Mux_in[0] = alu_result;
	mux2_1 #(.WIDTH(64)) Shift_Mux (.mux_out(EX_out[0]), .mux_in(Shift_Mux_in), .sel(Shift[1]));
	D_FF_en #(.WIDTH(64)) EX_out_FF0 (.q(EX_out[1]), .d(EX_out[0]), .reset(rst), .clk(clk), .en(1'b1));

	// Flag registers
	logic flag_negative, flag_overflow, flag_zero, flag_carryout;
	D_FF_en #(.WIDTH(1)) NFreg (.d(alu_NF),
				   .q(flag_negative),
				   .en(FlagEn[1]),
				   .clk,
				   .reset(rst));
	D_FF_en #(.WIDTH(1)) OFreg (.d(alu_OF),
				   .q(flag_overflow),
				   .en(FlagEn[1]),
				   .clk,
				   .reset(rst));
	D_FF_en #(.WIDTH(1)) ZFreg (.d(alu_ZF),
				   .q(flag_zero),
				   .en(FlagEn[1]),
				   .clk,
				   .reset(rst));
	D_FF_en #(.WIDTH(1)) Coutreg (.d(alu_Cout),
				   .q(flag_carryout),
				   .en(FlagEn[1]),
				   .clk,
				   .reset(rst));

	logic [63:0] Reg_RdData2_mem;
	D_FF_en #(.WIDTH(64)) RdData2_Ex_FF(.q(Reg_RdData2_mem), .d(Reg_RdData2_ex), .reset(rst), .clk(clk), .en(1'b1));
	//------------------------------------------------------------------------------------------
	// Mem Stage
	//------------------------------------------------------------------------------------------

	// Forwarding unit to obtain data from writeback stage
	logic [ 1:0] fwSel3;
	fw_unit fw_unit3 (.SourceReg(Rd_mem), .DestReg1(Reg_WrAddr[3]), .DestReg2(5'h1F), .WrEn1(RegWrite[3]), .WrEn2(1'b0), .Fw_SourceReg(fwSel3));
	logic [ 1:0][63:0] fwMux3_in;
	logic       [63:0] fwMux3_out;
	assign fwMux3_in[0] = Reg_RdData2_mem;
	assign fwMux3_in[1] = Reg_WrData;
	mux2_1 #(.WIDTH(64)) fwMux3 (.mux_out(fwMux3_out), .mux_in(fwMux3_in), .sel(fwSel3[0]));

	// DataMem
	logic [63:0] datamem_RdData;
	datamem DataMem0 (.address(EX_out[1]),
					  .write_enable(MemWrite[2]),
					  .read_enable(MemToReg[2]),                 // only read during LDUR
					  .write_data(fwMux3_out),
					  .clk,
					  .xfer_size(4'd8),                      // memory reads are word-aligned, so align for 8 byte-addresses
					  .read_data(datamem_RdData));

	// MemToReg Mux
	logic [63:0] MemToRegData_wb;
	logic [ 1:0][63:0] MemToReg_Mux_in;
	assign MemToReg_Mux_in[0] = EX_out[1];
	assign MemToReg_Mux_in[1] = datamem_RdData;
	mux2_1 #(.WIDTH(64)) MemToReg_Mux (.mux_out(MemToRegData), .mux_in(MemToReg_Mux_in), .sel(MemToReg[2]));
	D_FF_en #(.WIDTH(64)) MemToRegData_FF(.q(MemToRegData_wb), .d(MemToRegData), .reset(rst), .clk(clk), .en(1'b1));

	//------------------------------------------------------------------------------------------
	// Writeback Stage
	//------------------------------------------------------------------------------------------
	assign Reg_WrData = MemToRegData_wb;

	//------------------------------------------------------------------------------------------
	// Control Logic
	//------------------------------------------------------------------------------------------
	always_comb begin
		casex (instr)
			BOp: controls = 13'b0000011000000;
			BLTOp: begin
				if ((!FlagEn[1] && (flag_negative != flag_overflow)) || (FlagEn[1] && (alu_NF != alu_OF))) // If flags are being updated, use ALU out
																										   // If flags are not being updated, use flag registers
					controls = 13'b0000010000000;
				else
					controls = 13'b0000000000000;
			end
			CBZOp: begin
				if (BrZero)
					controls = 13'b0000010000000;
				else
					controls = 13'b0000000000000;
			end
			ADDSOp: controls = 13'b1001000010001;
			SUBSOp: controls = 13'b1001000011001;
			ANDOp: controls = 13'b1001000100000;
			EOROp: controls = 13'b1001000110000;
			LSROp: controls = 13'b0001000000010;
			ADDIOp: controls = 13'b0101000010100;
			LDUROp: controls = 13'b0111000010000;
			STUROp: controls = 13'b0100100010000;
			default: controls = 13'b0;
		endcase
	end
endmodule