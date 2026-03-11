module alu(
	input logic[31 : 0] i_a,
	input logic[31 : 0] i_b,
	
	input logic[5 : 0] alu_op,

	output logic [31 : 0] o_alu
);

	// alu rv32i opcodes
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

	always_comb begin
		case(alu_op)
			OP_ALU_ADD : o_alu = i_a + i_b;
			OP_ALU_SUB : o_alu = i_a - i_b;
			OP_ALU_AND : o_alu = i_a & i_b;
			OP_ALU_OR  : o_alu = i_a | i_b;
			OP_ALU_XOR : o_alu = i_a ^ i_b;
			OP_ALU_SLL : o_alu = i_a << i_b[4 : 0];
			OP_ALU_SRL : o_alu = i_a >> i_b[4 : 0];
			OP_ALU_SRA : o_alu = i_a >>> i_b[4 : 0];
			OP_ALU_SLT  : o_alu = ($signed(i_a) < $signed(i_b)) ? 32'd1 : 32'd0;
            		OP_ALU_SLTU : o_alu = (i_a < i_b)                   ? 32'd1 : 32'd0;
			default : o_alu = '0;
		endcase
	end

endmodule
