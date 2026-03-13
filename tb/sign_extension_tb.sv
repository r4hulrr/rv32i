`timescale 1ns/1ps

module sign_extension_tb;

	// DUT signals
	logic [31:0] inst;
	logic [6:0]  op;
	logic [31:0] imm;

	// Instantiate DUT
	sign_extension dut (
		.i_inst (inst),
		.i_op   (op),
		.o_imm  (imm)
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

	// Task
	task check(
		input logic [31:0] i_inst,
		input logic [6:0]  i_op,
		input logic [31:0] expected,
		input string       label
	);
		inst = i_inst;
		op   = i_op;
		#1;
		if (imm === expected)
		$display("PASS | %s | got=0x%08X", label, imm);
		else
		$display("FAIL | %s | expected=0x%08X got=0x%08X", label, expected, imm);
	endtask

	// Tests
	initial begin

	inst = 0; op = 0;
	#5;

	// I-type: ALUI positive immediate
	// ADDI x1, x0, 5  : inst[31:20] = 12'h005, sign bit = 0
	$display("\nI-type (ALUI/LOAD/JALR)");
	check(
		32'b0000_0000_0101_00000_000_00001_0010011,
		OP_ALUI,
		32'h00000005,
		"ADDI positive imm=5"
	);
	// ADDI x1, x0, -1 → inst[31:20] = 12'hFFF, sign bit = 1
	check(
		32'b1111_1111_1111_00000_000_00001_0010011,
		OP_ALUI,
		32'hFFFFFFFF,
		"ADDI negative imm=-1"
	);
	// ADDI x1, x0, -2048 → inst[31:20] = 12'h800
	check(
		32'b1000_0000_0000_00000_000_00001_0010011,
		OP_ALUI,
		32'hFFFFF800,
		"ADDI min negative imm=-2048"
	);
	// LW positive immediate
	check(
		32'b0000_0000_1000_00001_010_00010_0000011,
		OP_LOAD,
		32'h00000008,
		"LW positive imm=8"
	);
	// JALR negative immediate
	check(
		32'b1111_1111_1100_00001_000_00000_1100111,
		OP_JALR,
		32'hFFFFFFFC,
		"JALR negative imm=-4"
	);

	// S-type: STORE
	$display("\nS-type (STORE)");
	// SW with positive offset 8 → inst[31:25]=0, inst[11:7]=01000
	check(
		32'b0000_0000_0001_00010_010_01000_0100011,
		OP_STORE,
		32'h00000008,
		"SW positive offset=8"
	);
	// SW with negative offset -4 → inst[31:25]=1111111, inst[11:7]=11100
	check(
		32'b1111_1110_0001_00010_010_11100_0100011,
		OP_STORE,
		32'hFFFFFFFC,
		"SW negative offset=-4"
	);

	// U-type: LUI / AUIPC
	$display("\nU-type (LUI/AUIPC)");
	// LUI x1, 0x12345 → upper 20 bits = 0x12345, lower 12 = 0
	check(
		32'b0001_0010_0011_0100_0101_00001_0110111,
		OP_LUI,
		32'h12345000,
		"LUI 0x12345"
	);
	// LUI with all upper bits set
	check(
		32'b1111_1111_1111_1111_1111_00001_0110111,
		OP_LUI,
		32'hFFFFF000,
		"LUI all ones upper"
	);
	// AUIPC
	check(
		32'b0001_0010_0011_0100_0101_00001_0010111,
		OP_AUIPC,
		32'h12345000,
		"AUIPC 0x12345"
	);

	// J-type: JAL
	$display("\nJ-type (JAL)");
	// JAL positive offset +4
	// imm[20]=0 imm[10:1]=0000000010 imm[11]=0 imm[19:12]=00000000
	check(
		32'b0_0000000_0010_0_00000000_00000_1101111,
		OP_JAL,
		32'h00000004,
		"JAL positive offset=+4"
	);
	// JAL negative offset -4
	// sign bit = 1
	check(
		32'b1_1111111_1110_1_11111111_00000_1101111,
		OP_JAL,
		32'hFFFFFFFC,
		"JAL negative offset=-4"
	);

	// B-type: BRANCH
$display("\nB-type (BRANCH)");

	// BEQ positive offset +8
	check(
		32'b0_000000_00000_00000_000_0100_0_1100011,
		OP_BRANCH,
		32'h00000008,
		"BEQ positive offset=+8"
	);

	// BEQ negative offset -4
	check(
		32'b1_111111_00000_00000_000_1110_1_1100011,
		OP_BRANCH,
		32'hFFFFFFFC,
		"BEQ negative offset=-4"
	);

	// default
	$display("\nDefault");
	check(
		32'hDEADBEEF,
		OP_ALU,
		32'hFFFFFFFF,
		"ALU op returns default"
	);

	$display("\nDone");
	$finish;
	end

endmodule
