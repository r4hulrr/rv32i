`timescale 1ns/1ps

module alu_tb;

	// DUT signals
	logic [31:0] a;
	logic [31:0] b;
	logic [5:0]  alu_op;
	logic [31:0] result;

	// ALU is combinational so no clock needed
	// but we still use a small delay between tests

	// Instantiate DUT
	alu dut (
	.i_a      (a),
	.i_b      (b),
	.i_alu_op (alu_op),
	.o_alu    (result)
	);

	// alu opcodes
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

	// Task
	task check(
		input logic [5:0]  op,
		input logic [31:0] i_a,
		input logic [31:0] i_b,
		input logic [31:0] expected,
		input string       label
	);
		alu_op = op;
		a      = i_a;
		b      = i_b;
		#1;
		if (result === expected)
		    $display("PASS | %-20s | a=0x%08X b=0x%08X | got=0x%08X", label, i_a, i_b, result);
		else
		    $display("FAIL | %-20s | a=0x%08X b=0x%08X | expected=0x%08X | got=0x%08X",
			      label, i_a, i_b, expected, result);
	endtask

	// Tests
	initial begin

	a = 0; b = 0; alu_op = OP_ALU_NOP;
	#5;

	// ADD
	$display("\nADD");
	check(OP_ALU_ADD, 32'd10,         32'd20,         32'd30,          "10 + 20");
	check(OP_ALU_ADD, 32'hFFFFFFFF,   32'd1,          32'd0,           "overflow wrap");
	check(OP_ALU_ADD, 32'd0,          32'd0,          32'd0,           "0 + 0");

	// SUB
	$display("\nSUB");
	check(OP_ALU_SUB, 32'd30,         32'd10,         32'd20,          "30 - 10");
	check(OP_ALU_SUB, 32'd0,          32'd1,          32'hFFFFFFFF,    "underflow wrap");
	check(OP_ALU_SUB, 32'd5,          32'd5,          32'd0,           "x - x = 0");

	// AND
	$display("\nAND");
	check(OP_ALU_AND, 32'hFFFFFFFF,   32'h0F0F0F0F,   32'h0F0F0F0F,   "FF & 0F");
	check(OP_ALU_AND, 32'hAAAAAAAA,   32'h55555555,   32'h00000000,   "alternating bits");

	// OR
	$display("\nOR");
	check(OP_ALU_OR,  32'hAAAAAAAA,   32'h55555555,   32'hFFFFFFFF,   "alternating bits");
	check(OP_ALU_OR,  32'h00000000,   32'h00000000,   32'h00000000,   "0 | 0");

	// XOR
	$display("\nXOR");
	check(OP_ALU_XOR, 32'hFFFFFFFF,   32'hFFFFFFFF,   32'h00000000,   "FF ^ FF = 0");
	check(OP_ALU_XOR, 32'hAAAAAAAA,   32'h55555555,   32'hFFFFFFFF,   "alternating bits");

	// SLL
	$display("\nSLL");
	check(OP_ALU_SLL, 32'd1,          32'd4,          32'd16,          "1 << 4");
	check(OP_ALU_SLL, 32'h00000001,   32'd31,         32'h80000000,   "1 << 31");
	// only bottom 5 bits of b used
	check(OP_ALU_SLL, 32'd1,          32'hFFFFFFE4,   32'd16,          "shift mask b[4:0]=4");

	// SRL
	$display("\nSRL");
	check(OP_ALU_SRL, 32'd16,         32'd4,          32'd1,           "16 >> 4");
	check(OP_ALU_SRL, 32'h80000000,   32'd1,          32'h40000000,   "msb no sign extend");

	// SRA
	$display("\nSRA");
	check(OP_ALU_SRA, 32'h80000000,   32'd1,          32'hC0000000,   "negative sign extend");
	check(OP_ALU_SRA, 32'd16,         32'd4,          32'd1,           "positive no change");

	// SLT (signed)
	$display("\nSLT");
	check(OP_ALU_SLT, 32'd1,          32'd2,          32'd1,           "1 < 2 = 1");
	check(OP_ALU_SLT, 32'd2,          32'd1,          32'd0,           "2 < 1 = 0");
	check(OP_ALU_SLT, 32'hFFFFFFFF,   32'd1,          32'd1,           "-1 < 1 signed = 1");
	check(OP_ALU_SLT, 32'd1,          32'hFFFFFFFF,   32'd0,           "1 < -1 signed = 0");

	// SLTU (unsigned)
	$display("\nSLTU");
	check(OP_ALU_SLTU, 32'd1,         32'd2,          32'd1,           "1 < 2 unsigned = 1");
	check(OP_ALU_SLTU, 32'hFFFFFFFF,  32'd1,          32'd0,           "UINT_MAX < 1 = 0");
	check(OP_ALU_SLTU, 32'd1,         32'hFFFFFFFF,   32'd1,           "1 < UINT_MAX = 1");

	// NOP/default
	$display("\nNOP");
	check(OP_ALU_NOP, 32'hDEADBEEF,  32'hCAFEBABE,   32'd0,           "nop = 0");

	$display("\nDone");
	$finish;
	end
endmodule
