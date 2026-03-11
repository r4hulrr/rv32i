`timescale 1ns/1ps
module branch_unit(
	input logic i_branch,
	input logic [2 : 0] i_branch_op,
	input logic [31 : 0] i_a,
	input logic [31 : 0] i_b,

	output logic o_take
);

	localparam logic [2:0] BRANCH_BEQ      = 3'b000; // Branch Equal
	localparam logic [2:0] BRANCH_BNE      = 3'b001; // Branch Not Equal
	localparam logic [2:0] BRANCH_JAL_JALR = 3'b010; // Jump for JAL/JALR
	localparam logic [2:0] BRANCH_BLT      = 3'b100; // Branch Less Than
	localparam logic [2:0] BRANCH_BGE      = 3'b101; // Branch Greater Than Or Equal
	localparam logic [2:0] BRANCH_BLTU     = 3'b110; // Branch Less Than Unsigned
	localparam logic [2:0] BRANCH_BGEU     = 3'b111; // Branch Greater Than Or Equal Unsigned

	logic take;

	always_comb begin
		case(i_branch_op)
			BRANCH_BEQ : take 	= (i_a == i_b);
			BRANCH_BNE : take 	= (i_a != i_b);
			BRANCH_JAL_JALR : take 	= 1;
			BRANCH_BLT : take 	= ($signed(i_a) < $signed(i_b));
			BRANCH_BGE : take 	= ($signed(i_a) >= $signed(i_b));
			BRANCH_BLTU : take 	= (i_a < i_b);
			BRANCH_BGEU : take 	= (i_a >= i_b);
			default : take		= 1'b0;
		endcase
	end

	assign o_take = i_branch & take;
endmodule
