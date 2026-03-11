`timescale 1ns/1ps

module branch_unit_tb;

	// DUT signals
	logic        branch;
	logic [2:0]  branch_op;
	logic [31:0] a;
	logic [31:0] b;
	logic        take;

	// Instantiate DUT
	branch_unit dut (
		.i_branch     (branch),
		.i_branch_op  (branch_op),
		.i_a          (a),
		.i_b          (b),
		.o_take       (take)
	);

	// Opcodes
	localparam logic [2:0] BRANCH_BEQ      = 3'b000;
	localparam logic [2:0] BRANCH_BNE      = 3'b001;
	localparam logic [2:0] BRANCH_JAL_JALR = 3'b010;
	localparam logic [2:0] BRANCH_BLT      = 3'b100;
	localparam logic [2:0] BRANCH_BGE      = 3'b101;
	localparam logic [2:0] BRANCH_BLTU     = 3'b110;
	localparam logic [2:0] BRANCH_BGEU     = 3'b111;

	// Task
	task check(
		input logic        i_branch,
		input logic [2:0]  op,
		input logic [31:0] i_a,
		input logic [31:0] i_b,
		input logic        expected,
		input string       label
	);
		branch    = i_branch;
		branch_op = op;
		a         = i_a;
		b         = i_b;
		#1;
		if (take === expected)
		    $display("PASS | %-30s | a=0x%08X b=0x%08X | take=%0b", label, i_a, i_b, take);
		else
		    $display("FAIL | %-30s | a=0x%08X b=0x%08X | expected=%0b got=%0b",
			      label, i_a, i_b, expected, take);
	endtask

	// Tests
	initial begin

	branch = 0; branch_op = 0; a = 0; b = 0;
	#5;

	// i_branch gate
	$display("\ni_branch gate");
	check(1'b0, BRANCH_BEQ,      32'd5,        32'd5,        1'b0, "branch=0 blocks take");
	check(1'b0, BRANCH_JAL_JALR, 32'd0,        32'd0,        1'b0, "branch=0 blocks JAL");

	// BEQ
	$display("\nBEQ");
	check(1'b1, BRANCH_BEQ, 32'd5,          32'd5,          1'b1, "5 == 5");
	check(1'b1, BRANCH_BEQ, 32'd5,          32'd6,          1'b0, "5 != 6");
	check(1'b1, BRANCH_BEQ, 32'h00000000,   32'h00000000,   1'b1, "0 == 0");
	check(1'b1, BRANCH_BEQ, 32'hFFFFFFFF,   32'hFFFFFFFF,   1'b1, "UINT_MAX == UINT_MAX");

	// BNE
	$display("\nBNE");
	check(1'b1, BRANCH_BNE, 32'd5,          32'd6,          1'b1, "5 != 6");
	check(1'b1, BRANCH_BNE, 32'd5,          32'd5,          1'b0, "5 == 5 no branch");

	// BLT (signed)
	$display("\nBLT");
	check(1'b1, BRANCH_BLT, 32'd1,          32'd2,          1'b1, "1 < 2");
	check(1'b1, BRANCH_BLT, 32'd2,          32'd1,          1'b0, "2 < 1 = false");
	check(1'b1, BRANCH_BLT, 32'd5,          32'd5,          1'b0, "5 < 5 = false");
	check(1'b1, BRANCH_BLT, 32'hFFFFFFFF,   32'd1,          1'b1, "-1 < 1 signed");
	check(1'b1, BRANCH_BLT, 32'd1,          32'hFFFFFFFF,   1'b0, "1 < -1 = false signed");

	// BGE (signed)
	$display("\nBGE");
	check(1'b1, BRANCH_BGE, 32'd2,          32'd1,          1'b1, "2 >= 1");
	check(1'b1, BRANCH_BGE, 32'd5,          32'd5,          1'b1, "5 >= 5 equal");
	check(1'b1, BRANCH_BGE, 32'd1,          32'd2,          1'b0, "1 >= 2 = false");
	check(1'b1, BRANCH_BGE, 32'd1,          32'hFFFFFFFF,   1'b1, "1 >= -1 signed");

	// BLTU
	$display("\nBLTU");
	check(1'b1, BRANCH_BLTU, 32'd1,         32'd2,          1'b1, "1 < 2 unsigned");
	check(1'b1, BRANCH_BLTU, 32'd2,         32'd1,          1'b0, "2 < 1 = false unsigned");
	check(1'b1, BRANCH_BLTU, 32'd1,         32'hFFFFFFFF,   1'b1, "1 < UINT_MAX");
	check(1'b1, BRANCH_BLTU, 32'hFFFFFFFF,  32'd1,          1'b0, "UINT_MAX < 1 = false");

	// BGEU
	$display("\nBGEU");
	check(1'b1, BRANCH_BGEU, 32'd2,         32'd1,          1'b1, "2 >= 1 unsigned");
	check(1'b1, BRANCH_BGEU, 32'd5,         32'd5,          1'b1, "5 >= 5 equal unsigned");
	check(1'b1, BRANCH_BGEU, 32'hFFFFFFFF,  32'd1,          1'b1, "UINT_MAX >= 1");
	check(1'b1, BRANCH_BGEU, 32'd1,         32'hFFFFFFFF,   1'b0, "1 >= UINT_MAX = false");

	// JAL/JALR always takes
	$display("\nJAL_JALR");
	check(1'b1, BRANCH_JAL_JALR, 32'd0,     32'd0,          1'b1, "JAL always take");
	check(1'b1, BRANCH_JAL_JALR, 32'hDEAD,  32'hBEEF,       1'b1, "JALR always take");

	// default
	$display("\nDefault");
	check(1'b1, 3'b011,          32'd0,      32'd0,          1'b0, "unused op = 0");
	check(1'b1, 3'b111,          32'd0,      32'd0,          1'b1, "BGEU 0 >= 0");

	$display("\nDone"); 
	$finish;
	end

endmodule
