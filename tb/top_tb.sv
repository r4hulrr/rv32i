`timescale 1ns/1ps

module top_tb;

	localparam CLK_PERIOD = 10;
	localparam MAX_CYCLES = 500;

	logic        clk;
	logic        rst;
	logic [31:0] o_result;

	top dut (
		.i_clk    (clk),
		.i_rst    (rst),
		.o_result (o_result)
	);

	initial clk = 0;
	always #(CLK_PERIOD/2) clk = ~clk;

	logic [31:0] expected [0:31];

	task automatic init_expected();
		for (int i = 0; i < 32; i++) expected[i] = 32'hX;
		expected[0]  = 32'h00000000;  // x0  hardwired zero
		expected[1]  = 32'h00000005;  // ADDI  x1=5
		expected[2]  = 32'h0000000A;  // ADDI  x2=10
		expected[3]  = 32'h00000002;  // ADDI  x3=2 (shift amount)
		expected[4]  = 32'h0000000A;  // SLLI  x4=x1<<1=10
		expected[5]  = 32'h00000001;  // SLTI  x5=(5<10)=1
		expected[6]  = 32'h00000003;  // XORI  x6=0^3=3
		expected[7]  = 32'h0000000E;  // ORI   x7=0|14=14
		expected[8]  = 32'h0000000A;  // ANDI  x8=10&15=10
		expected[9]  = 32'h00000005;  // SRLI  x9=10>>1=5
		expected[10] = 32'h00000002;  // SRAI  x10=5>>>1=2
		expected[11] = 32'h0000000F;  // ADD   x11=5+10=15
		expected[12] = 32'hFFFFFFFB;  // SUB   x12=5-10=-5
		expected[13] = 32'h00000000;  // AND   x13=5&10=0
		expected[14] = 32'h0000000F;  // OR    x14=5|10=15
		expected[15] = 32'h0000000F;  // XOR   x15=5^10=15
		expected[16] = 32'h00000014;  // SLL   x16=5<<2=20
		expected[17] = 32'h00000002;  // SRL   x17=10>>2=2
		expected[18] = 32'hFFFFFFFE;  // SRA   x18=-5>>>2=-2
		expected[19] = 32'h00000001;  // SLT   x19=(5<10)=1
		expected[20] = 32'h00000000;  // SLT   x20=(10<5)=0
		expected[21] = 32'h00000001;  // SLTU  x21=(5<10)u=1
		expected[22] = 32'h00001000;  // LUI   x22=0x1000
		expected[23] = 32'h00000058;  // AUIPC x23=PC=0x58
		expected[24] = 32'h00000005;  // LW    x24=mem[x22]=5
		expected[25] = 32'h00000068;  // JAL   x25=PC+4=0x68
		expected[26] = 32'h0000007C;  // ADDI  x26=jalr target=0x7C
		expected[27] = 32'h00000078;  // JALR  x27=PC+4=0x78
	endtask

	function automatic string decode(input logic [31:0] inst);
		logic [6:0] op; logic [2:0] f3; logic [6:0] f7;
		op=inst[6:0]; f3=inst[14:12]; f7=inst[31:25];
		case (op)
			7'h13: case(f3)
				3'b000: return "ADDI";  3'b001: return "SLLI";
				3'b010: return "SLTI";  3'b011: return "SLTIU";
				3'b100: return "XORI";  3'b101: return f7[5] ? "SRAI":"SRLI";
				3'b110: return "ORI";   3'b111: return "ANDI";
				default: return "ALU-I";
			endcase
			7'h33: case(f3)
				3'b000: return f7[5] ? "SUB":"ADD";
				3'b001: return "SLL";   3'b010: return "SLT";
				3'b011: return "SLTU";  3'b100: return "XOR";
				3'b101: return f7[5] ? "SRA":"SRL";
				3'b110: return "OR";    3'b111: return "AND";
				default: return "ALU-R";
			endcase
			7'h03: return "LW";     7'h23: return "SW";
			7'h6F: return "JAL";    7'h67: return "JALR";
			7'h37: return "LUI";    7'h17: return "AUIPC";
			7'h63: case(f3)
				3'b000: return "BEQ";   3'b001: return "BNE";
				3'b100: return "BLT";   3'b101: return "BGE";
				3'b110: return "BLTU";  3'b111: return "BGEU";
				default: return "BR";
			endcase
			default: return "???";
		endcase
	endfunction

	int pass_count, fail_count;

	task automatic check_regfile();
		$display("\n--- Register File ---");
		pass_count = 0; fail_count = 0;
		for (int i = 0; i < 32; i++) begin
			if (expected[i] !== 32'hX) begin
				if (dut.regs.reg_mem[i] === expected[i]) begin
					$display("  PASS | x%-2d = 0x%08X", i, dut.regs.reg_mem[i]);
					pass_count++;
				end else begin
					$display("  FAIL | x%-2d = 0x%08X  (expected 0x%08X)",
						i, dut.regs.reg_mem[i], expected[i]);
					fail_count++;
				end
			end
		end
		$display("\n  %0d PASS  |  %0d FAIL", pass_count, fail_count);
		if (fail_count == 0)
			$display("  ALL CHECKS PASSED\n");
		else
			$display("  SOME CHECKS FAILED — see above\n");
	endtask

	int   cycle_count;

	initial begin
		init_expected();
		cycle_count = 0;

		rst = 1;
		repeat(2) @(posedge clk);
		#1; rst = 0;

		$display("\n=== RV32I CPU Integration Test ===\n");
		$display("  %5s  %6s  %-6s  %s", "cycle", "PC", "inst", "o_result");
		$display("  -------------------------------------------");

		fork
			begin : monitor
				forever begin
					@(posedge clk); #1;
					$display("  %5d  0x%04X  %-6s  0x%08X",
						cycle_count, dut.pc, decode(dut.inst), o_result);
					cycle_count++;
				end
			end
			begin : detector
				logic [31:0] prev_pc;
				prev_pc = 32'hFFFFFFFF;
				forever begin
					@(posedge clk); #1;
					if (dut.pc === prev_pc) begin
						disable monitor;
						disable watchdog;
						$display("\n  [Halted at PC=0x%04X after %0d cycles]", dut.pc, cycle_count);
						check_regfile();
						$finish;
					end
					prev_pc = dut.pc;
				end
			end
			begin : watchdog
				repeat(MAX_CYCLES) @(posedge clk);
				disable monitor;
				disable detector;
				$display("\n  [WATCHDOG: no halt within %0d cycles, last PC=0x%04X]",
					MAX_CYCLES, dut.pc);
				check_regfile();
				$finish;
			end
		join
	end

endmodule
