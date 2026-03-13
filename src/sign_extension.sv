`timescale 1ns/1ps
module sign_extension(
	input logic [31 : 0] i_inst,
	input logic [6 : 0] i_op,
	
	output logic [31 : 0] o_imm
);

	localparam logic [7 : 0] OP_LUI     = 7'b0110111; // Load Upper Immediate
	localparam logic [7 : 0] OP_AUIPC   = 7'b0010111; // Add Upper Immediate to PC
	localparam logic [7 : 0] OP_JAL     = 7'b1101111; // Jump and Link
	localparam logic [7 : 0] OP_JALR    = 7'b1100111; // Jump and Link Register
	localparam logic [7 : 0] OP_BRANCH  = 7'b1100011; // Branch Instructions 
	localparam logic [7 : 0] OP_LOAD    = 7'b0000011; // Load Instructions
	localparam logic [7 : 0] OP_STORE   = 7'b0100011; // Store Instructions 
	localparam logic [7 : 0] OP_ALU     = 7'b0110011; // ALU Instructions 
	localparam logic [7 : 0] OP_ALUI    = 7'b0010011; // ALU Immediate Instructions

	always_comb begin
		case(i_op)
			// I-type: inst[31:20]  12-bit immediate
			OP_ALUI,
			OP_LOAD,
			OP_JALR  : o_imm = {{20{i_inst[31]}}, i_inst[31:20]};

			// S-type: inst[31:25] | inst[11:7]  12-bit immediate
			OP_STORE : o_imm = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};

			// U-type: inst[31:12] 20-bit immediate, zero lower 12
			OP_LUI,
			OP_AUIPC : o_imm = {i_inst[31:12], 12'h000};

			// J-type: JAL 21-bit immediate
			OP_JAL   : o_imm = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12],
					  i_inst[20], i_inst[30:21], 1'b0};

			// B-type: branch 13-bit immediate
			OP_BRANCH: o_imm = {{19{i_inst[31]}}, i_inst[31], i_inst[7],
					  i_inst[30:25], i_inst[11:8], 1'b0};

			default  : o_imm = 32'hFFFF_FFFF;
		endcase	
	end

endmodule

