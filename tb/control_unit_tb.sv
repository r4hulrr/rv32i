`timescale 1ns/1ps

module control_unit_tb;

	// DUT signals
	logic [31:0] inst;
	logic [6:0]  opcode;
	logic [4:0]  rs1_addr;
	logic [4:0]  rs2_addr;
	logic [4:0]  rd_addr;
	logic        reg_write;
	logic        mem_write;
	logic        branch;
	logic        alu_src_a;
	logic        alu_src_b;
	logic [1:0]  result_mux;
	logic [2:0]  branch_op;
	logic [5:0]  alu_op;

	// Instantiate DUT
	control_unit dut (
		.i_inst       (inst),
		.o_opcode     (opcode),
		.o_rs1_addr   (rs1_addr),
		.o_rs2_addr   (rs2_addr),
		.o_rd_addr    (rd_addr),
		.o_reg_write  (reg_write),
		.o_mem_write  (mem_write),
		.o_branch     (branch),
		.o_alu_src_a  (alu_src_a),
		.o_alu_src_b  (alu_src_b),
		.o_result_mux (result_mux),
		.o_branch_op  (branch_op),
		.o_alu_op     (alu_op)
	);

	// Opcodes
	localparam logic [6:0] OP_LUI    = 7'b0110111;
	localparam logic [6:0] OP_AUIPC  = 7'b0010111;
	localparam logic [6:0] OP_JAL    = 7'b1101111;
	localparam logic [6:0] OP_JALR   = 7'b1100111;
	localparam logic [6:0] OP_BRANCH = 7'b1100011;
	localparam logic [6:0] OP_LOAD   = 7'b0000011;
	localparam logic [6:0] OP_STORE  = 7'b0100011;
	localparam logic [6:0] OP_ALU    = 7'b0110011;
	localparam logic [6:0] OP_ALUI   = 7'b0010011;

	// ALU ops
	localparam logic [5:0] OP_ALU_NOP  = 6'b000000;
	localparam logic [5:0] OP_ALU_ADD  = 6'b011001;
	localparam logic [5:0] OP_ALU_SUB  = 6'b011011;
	localparam logic [5:0] OP_ALU_AND  = 6'b011101;
	localparam logic [5:0] OP_ALU_OR   = 6'b011111;
	localparam logic [5:0] OP_ALU_XOR  = 6'b100001;
	localparam logic [5:0] OP_ALU_SLT  = 6'b100011;
	localparam logic [5:0] OP_ALU_SLTU = 6'b100101;
	localparam logic [5:0] OP_ALU_SLL  = 6'b100111;
	localparam logic [5:0] OP_ALU_SRL  = 6'b101001;
	localparam logic [5:0] OP_ALU_SRA  = 6'b101011;

	// Branch ops
	localparam logic [2:0] BRANCH_BEQ      = 3'b000;
	localparam logic [2:0] BRANCH_BNE      = 3'b001;
	localparam logic [2:0] BRANCH_JAL_JALR = 3'b010;
	localparam logic [2:0] BRANCH_BLT      = 3'b100;
	localparam logic [2:0] BRANCH_BGE      = 3'b101;
	localparam logic [2:0] BRANCH_BLTU     = 3'b110;
	localparam logic [2:0] BRANCH_BGEU     = 3'b111;

	// Task
	task check_signals(
		input logic [31:0] i_inst,
		input logic        exp_reg_write,
		input logic        exp_mem_write,
		input logic        exp_branch,
		input logic        exp_alu_src_a,
		input logic        exp_alu_src_b,
		input logic [1:0]  exp_result_mux,
		input logic [2:0]  exp_branch_op,
		input logic [5:0]  exp_alu_op,
		input string       label
	);
		inst = i_inst;
		#1;
		if (reg_write  === exp_reg_write  &&
			mem_write  === exp_mem_write  &&
			branch     === exp_branch     &&
			alu_src_a  === exp_alu_src_a  &&
			alu_src_b  === exp_alu_src_b  &&
			result_mux === exp_result_mux &&
			branch_op  === exp_branch_op  &&
			alu_op     === exp_alu_op)
			$display("PASS | %-35s", label);
		else begin
			$display("FAIL | %-35s", label);
			$display("       reg_write =%0b exp=%0b", reg_write,  exp_reg_write);
			$display("       mem_write =%0b exp=%0b", mem_write,  exp_mem_write);
			$display("       branch    =%0b exp=%0b", branch,     exp_branch);
			$display("       alu_src_a =%0b exp=%0b", alu_src_a,  exp_alu_src_a);
			$display("       alu_src_b =%0b exp=%0b", alu_src_b,  exp_alu_src_b);
			$display("       result_mux=%0b exp=%0b", result_mux, exp_result_mux);
			$display("       branch_op =%0b exp=%0b", branch_op,  exp_branch_op);
			$display("       alu_op    =%0b exp=%0b", alu_op,     exp_alu_op);
		end
	endtask

	task check_fields(
		input logic [31:0] i_inst,
		input logic [4:0]  exp_rs1,
		input logic [4:0]  exp_rs2,
		input logic [4:0]  exp_rd,
		input string       label
	);
		inst = i_inst;
		#1;
		if (rs1_addr === exp_rs1 &&
		    rs2_addr === exp_rs2 &&
		    rd_addr  === exp_rd)
		    $display("PASS | %-35s | rs1=x%0d rs2=x%0d rd=x%0d",
			      label, rs1_addr, rs2_addr, rd_addr);
		else
		    $display("FAIL | %-35s | rs1=x%0d exp=x%0d | rs2=x%0d exp=x%0d | rd=x%0d exp=x%0d",
			      label, rs1_addr, exp_rs1, rs2_addr, exp_rs2, rd_addr, exp_rd);
	endtask

	// Tests
	initial begin

	inst = 32'h0;
	#5;

	// register field extraction
	// ADD x3, x1, x2 → rd=3 rs1=1 rs2=2
	$display("\nRegister field extraction");
	check_fields(
	    32'b0000000_00010_00001_000_00011_0110011,
	    5'd1, 5'd2, 5'd3,
	    "ADD x3,x1,x2 fields"
	);

	// LW x5, 0(x6) → rd=5 rs1=6 rs2=don't care
	check_fields(
	    32'b000000000000_00110_010_00101_0000011,
	    5'd6, 5'd0, 5'd5,
	    "LW x5,0(x6) fields"
	);
	// LUI rs1 should be x0
	check_fields(
	    32'b00000000000000000001_00001_0110111,
	    5'd0, 5'd0, 5'd1,
	    "LUI x1 rs1 forced x0"
	);

	// LUI
	$display("\nLUI");
	check_signals(
	    32'b00000000000000000001_00001_0110111,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "LUI control signals"
	);

	// AUIPC
	$display("\nAUIPC");
	check_signals(
	    32'b00000000000000000001_00001_0010111,
	    1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "AUIPC control signals"
	);

	// JAL
	$display("\nJAL");
	check_signals(
	    32'b0_0000000_0010_0_00000000_00001_1101111,
	    1'b1, 1'b0, 1'b1, 1'b1, 1'b1, 2'b01, BRANCH_JAL_JALR, OP_ALU_ADD,
	    "JAL control signals"
	);

	// JALR
	$display("\nJALR");
	check_signals(
	    32'b000000000000_00001_000_00010_1100111,
	    1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 2'b01, BRANCH_JAL_JALR, OP_ALU_ADD,
	    "JALR control signals"
	);

	// BRANCH - one per funct3
	$display("\nBRANCH");
	// BEQ funct3=000
	check_signals(
	    32'b0000000_00010_00001_000_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "BEQ control signals"
	);
	// BNE funct3=001
	check_signals(
	    32'b0000000_00010_00001_001_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BNE, OP_ALU_ADD,
	    "BNE control signals"
	);
	// BLT funct3=100
	check_signals(
	    32'b0000000_00010_00001_100_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BLT, OP_ALU_ADD,
	    "BLT control signals"
	);
	// BGE funct3=101
	check_signals(
	    32'b0000000_00010_00001_101_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BGE, OP_ALU_ADD,
	    "BGE control signals"
	);
	// BLTU funct3=110
	check_signals(
	    32'b0000000_00010_00001_110_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BLTU, OP_ALU_ADD,
	    "BLTU control signals"
	);
	// BGEU funct3=111
	check_signals(
	    32'b0000000_00010_00001_111_00000_1100011,
	    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, BRANCH_BGEU, OP_ALU_ADD,
	    "BGEU control signals"
	);

	// LOAD
	$display("\nLOAD");
	check_signals(
	    32'b000000000000_00001_010_00010_0000011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b10, BRANCH_BEQ, OP_ALU_ADD,
	    "LW control signals"
	);

	// STORE
	$display("\nSTORE");
	check_signals(
	    32'b0000000_00010_00001_010_00000_0100011,
	    1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "SW control signals"
	);

	// ALU R-type
	$display("\nALU R-type");
	// ADD funct3=000 funct7[5]=0
	check_signals(
	    32'b0000000_00010_00001_000_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "ADD control signals"
	);
	// SUB funct3=000 funct7[5]=1
	check_signals(
	    32'b0100000_00010_00001_000_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_SUB,
	    "SUB control signals"
	);
	// AND funct3=111
	check_signals(
	    32'b0000000_00010_00001_111_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_AND,
	    "AND control signals"
	);
	// OR funct3=110
	check_signals(
	    32'b0000000_00010_00001_110_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_OR,
	    "OR control signals"
	);
	// XOR funct3=100
	check_signals(
	    32'b0000000_00010_00001_100_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_XOR,
	    "XOR control signals"
	);
	// SLL funct3=001
	check_signals(
	    32'b0000000_00010_00001_001_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_SLL,
	    "SLL control signals"
	);
	// SRL funct3=101 funct7[5]=0
	check_signals(
	    32'b0000000_00010_00001_101_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_SRL,
	    "SRL control signals"
	);
	// SRA funct3=101 funct7[5]=1
	check_signals(
	    32'b0100000_00010_00001_101_00011_0110011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_SRA,
	    "SRA control signals"
	);

	// ALU I-type immediate
	$display("\nALU I-type");
	// ADDI funct3=000
	check_signals(
	    32'b000000000001_00001_000_00010_0010011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
	    "ADDI control signals"
	);
	// SRLI funct3=101 funct7[5]=0
	check_signals(
	    32'b0000000_00001_00010_101_00011_0010011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_SRL,
	    "SRLI control signals"
	);
	// SRAI funct3=101 funct7[5]=1
	check_signals(
	    32'b0100000_00001_00010_101_00011_0010011,
	    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, BRANCH_BEQ, OP_ALU_SRA,
	    "SRAI control signals"
	);

	// default unrecognised opcode
	$display("\nDefault");
	check_signals(
		32'h0000007F,
		1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, BRANCH_BEQ, OP_ALU_ADD,
		"unknown opcode defaults"
	);

	$display("\nDone");
	$finish;
	end

endmodule
