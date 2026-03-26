`timescale 1ns/1ps

module top (
	input  logic        i_clk,
	input  logic        i_rst,

	output logic [31:0] o_result
);

	// PC
	logic [31:0] pc;
	logic [31:0] next_pc;
	logic        take;
	logic [31:0] alu_out;      // branch target (or any ALU result)
	logic [31:0] pc_plus4;

	assign pc_plus4 = pc + 4;

	always_ff @(posedge i_clk) begin
		if (i_rst)
			pc <= '0;
		else
			pc <= next_pc;
	end

	always_comb begin
		if (take)
        		next_pc = {alu_out[31:2], 2'b00};
    		else
        	next_pc = pc + 32'd4;
	end

	// Instruction memory
	logic [31:0] inst;

	instruction_mem imem (
		.i_addr (pc),
		.o_ins  (inst)
	);

	// Control unit
	logic [4:0] rs1_addr, rs2_addr, rd_addr;
	logic [6:0] opcode;
	logic       reg_write, mem_write, branch;
	logic       alu_src_a, alu_src_b;
	logic [1:0] result_mux;
	logic [2:0] branch_op;
	logic [5:0] alu_op;

	control_unit ctrl (
		.i_inst      (inst),
		.o_rs1_addr  (rs1_addr),
		.o_rs2_addr  (rs2_addr),
		.o_rd_addr   (rd_addr),
		.o_opcode    (opcode),
		.o_reg_write (reg_write),
		.o_mem_write (mem_write),
		.o_branch    (branch),
		.o_alu_src_a (alu_src_a),
		.o_alu_src_b (alu_src_b),
		.o_result_mux(result_mux),
		.o_branch_op (branch_op),
		.o_alu_op    (alu_op)
	);

	// Sign extension
	logic [31:0] imm;

	sign_extension sign_ext (
		.i_inst (inst),
		.i_op   (opcode),
		.o_imm  (imm)
	);

	// Register file
	logic [31:0] rs1, rs2;
	logic [31:0] result;   // writeback value 

	reg_file regs (
		.i_clk     (i_clk),
		.i_rst     (i_rst),
		.i_we      (reg_write),
		.i_wr      (result),
		.i_wr_addr (rd_addr),
		.i_rd1_addr(rs1_addr),
		.i_rd2_addr(rs2_addr),
		.o_rd1     (rs1),
		.o_rd2     (rs2)
	);

	// ALU input muxes
	logic [31:0] alu_a, alu_b;

	assign alu_a = alu_src_a ? pc  : rs1;
	assign alu_b = alu_src_b ? imm : rs2;

	// ALU
	alu alu_inst (
		.i_alu_op(alu_op),
		.i_a     (alu_a),
		.i_b     (alu_b),
		.o_alu   (alu_out)
	);

	// Data memory
	logic [31:0] mem_data;

	data_mem dmem (
		.i_clk  (i_clk),
		.i_rst  (i_rst),
		.i_we   (mem_write),
		.i_data (rs2),
		.i_addr (alu_out),
		.o_data (mem_data)
	);

	// Writeback mux
	always_comb begin
		case (result_mux)
			2'b00:   result = alu_out;   // ALU result
			2'b01:   result = pc_plus4;  // JAL/JALR return address
			2'b10:   result = mem_data;  // load
			default: result = '0;
		endcase
	end

	// Branch unit
	branch_unit bu (
		.i_branch   (branch),
		.i_branch_op(branch_op),
		.i_a        (rs1),
		.i_b        (rs2),
		.o_take     (take)
	);

	assign o_result = result;
endmodule
