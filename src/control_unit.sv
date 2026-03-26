`timescale 1ns/1ps

module control_unit (
	input  logic [31:0] i_inst,

	// register addresses
	output logic [4:0]  o_rs1_addr,
	output logic [4:0]  o_rs2_addr,
	output logic [4:0]  o_rd_addr,
	output logic [6:0]  o_opcode,

	// control signals
	output logic        o_reg_write,
	output logic        o_mem_write,
	output logic        o_branch,
	output logic        o_alu_src_a,  // 0=reg, 1=pc
	output logic        o_alu_src_b,  // 0=reg, 1=imm
	output logic [1:0]  o_result_mux, // 00=alu, 01=pc+4, 10=mem
	output logic [2:0]  o_branch_op,
	output logic [5:0]  o_alu_op
);
	// opcodes
	localparam logic [6:0] OP_LUI    = 7'b0110111;
	localparam logic [6:0] OP_AUIPC  = 7'b0010111;
	localparam logic [6:0] OP_JAL    = 7'b1101111;
	localparam logic [6:0] OP_JALR   = 7'b1100111;
	localparam logic [6:0] OP_BRANCH = 7'b1100011;
	localparam logic [6:0] OP_LOAD   = 7'b0000011;
	localparam logic [6:0] OP_STORE  = 7'b0100011;
	localparam logic [6:0] OP_ALU    = 7'b0110011;
	localparam logic [6:0] OP_ALUI   = 7'b0010011;

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

	// branch opcodes
	localparam logic [2:0] BRANCH_BEQ      = 3'b000;
	localparam logic [2:0] BRANCH_BNE      = 3'b001;
	localparam logic [2:0] BRANCH_JAL_JALR = 3'b010;
	localparam logic [2:0] BRANCH_BLT      = 3'b100;
	localparam logic [2:0] BRANCH_BGE      = 3'b101;
	localparam logic [2:0] BRANCH_BLTU     = 3'b110;
	localparam logic [2:0] BRANCH_BGEU     = 3'b111;

	// instruction fields
	logic [6:0] opcode;
	logic [6:0] funct7;
	logic [2:0] funct3;

	assign opcode = i_inst[6:0];
	assign funct7 = i_inst[31:25];
	assign funct3 = i_inst[14:12];

	assign o_opcode   = opcode;
	assign o_rd_addr  = i_inst[11:7];
	assign o_rs2_addr = i_inst[24:20];

	always_comb begin
		// defaults
		o_reg_write  = 1'b0;
		o_mem_write  = 1'b0;
		o_branch     = 1'b0;
		o_alu_src_a  = 1'b0;
		o_alu_src_b  = 1'b0;
		o_result_mux = 2'b00;
		o_branch_op  = BRANCH_BEQ;
		o_alu_op     = OP_ALU_ADD;
		o_rs1_addr   = i_inst[19:15];

		case (opcode)
			
			OP_LUI: begin
				o_reg_write = 1'b1;
				o_alu_src_b = 1'b1;
				o_rs1_addr  = 5'b0;      // LUI: rd = 0 + imm
			end

			OP_AUIPC: begin
				o_reg_write = 1'b1;
				o_alu_src_a = 1'b1;      // src_a = PC
				o_alu_src_b = 1'b1;      // src_b = imm
			end

			OP_JAL: begin
				o_reg_write  = 1'b1;
				o_branch     = 1'b1;
				o_alu_src_a  = 1'b1;     // PC + imm for branch target
				o_alu_src_b  = 1'b1;
				o_result_mux = 2'b01;    // write back PC+4
				o_branch_op  = BRANCH_JAL_JALR;
			end

			OP_JALR: begin
				o_reg_write  = 1'b1;
				o_branch     = 1'b1;
				o_alu_src_b  = 1'b1;     // rs1 + imm for branch target
				o_result_mux = 2'b01;    // write back PC+4
				o_branch_op  = BRANCH_JAL_JALR;
			end

			OP_BRANCH: begin
				o_branch = 1'b1;         // rs1 vs rs2
				case (funct3)
					BRANCH_BEQ  : o_branch_op = BRANCH_BEQ;
					BRANCH_BNE  : o_branch_op = BRANCH_BNE;
					BRANCH_BLT  : o_branch_op = BRANCH_BLT;
					BRANCH_BGE  : o_branch_op = BRANCH_BGE;
					BRANCH_BLTU : o_branch_op = BRANCH_BLTU;
					BRANCH_BGEU : o_branch_op = BRANCH_BGEU;
					default     : o_branch_op = BRANCH_BEQ;
				endcase
			end

			OP_LOAD: begin
				o_reg_write  = 1'b1;
				o_alu_src_b  = 1'b1;     // addr = rs1 + imm
				o_result_mux = 2'b10;    // write back mem data
			end

			OP_STORE: begin
				o_mem_write = 1'b1;
				o_alu_src_b = 1'b1;      // addr = rs1 + imm
			end

			OP_ALU: begin
				o_reg_write = 1'b1;
				case (funct3)
					3'b000: o_alu_op = (funct7 == 7'b0100000) ? OP_ALU_SUB : OP_ALU_ADD;
					3'b001: o_alu_op = OP_ALU_SLL;
					3'b010: o_alu_op = OP_ALU_SLT;
					3'b011: o_alu_op = OP_ALU_SLTU;
					3'b100: o_alu_op = OP_ALU_XOR;
					3'b101: o_alu_op = (funct7 == 7'b0100000) ? OP_ALU_SRA : OP_ALU_SRL;
					3'b110: o_alu_op = OP_ALU_OR;
					3'b111: o_alu_op = OP_ALU_AND;
					default: o_alu_op = OP_ALU_NOP;
				endcase
			end

			OP_ALUI: begin
				o_reg_write = 1'b1;
				o_alu_src_b = 1'b1;
				case (funct3)
					3'b000: o_alu_op = OP_ALU_ADD;
					3'b001: o_alu_op = OP_ALU_SLL;
					3'b010: o_alu_op = OP_ALU_SLT;
					3'b011: o_alu_op = OP_ALU_SLTU;
					3'b100: o_alu_op = OP_ALU_XOR;
					3'b101: o_alu_op = (funct7 == 7'b0100000) ? OP_ALU_SRA : OP_ALU_SRL;
					3'b110: o_alu_op = OP_ALU_OR;
					3'b111: o_alu_op = OP_ALU_AND;
					default: o_alu_op = OP_ALU_NOP;
				endcase
			end
		endcase
	end
endmodule
