`timescale 1ns/1ps

module data_mem #(
	parameter MEM_SIZE = 1024  // number of words (4KB)
)(
	input logic i_clk,
	input logic i_rst,

	input logic        i_we,
	input logic [2:0]  i_width,   // funct3: 000=LB/SB 001=LH/SH 010=LW/SW 100=LBU 101=LHU
	input logic [31:0] i_data,
	input logic [31:0] i_addr,

	output logic [31:0] o_data
);

	// Byte-addressable, MEM_SIZE*4 bytes total
	// Address is masked to fit: use low bits only
	localparam ADDR_BITS = $clog2(MEM_SIZE) + 2;  // byte address bits
	localparam DEPTH     = MEM_SIZE * 4;

	logic [7:0] mem [0 : DEPTH-1];

	// Byte address within array (mask to array size)
	logic [ADDR_BITS-1:0] baddr;
	assign baddr = i_addr[ADDR_BITS-1:0];

	always_ff @(posedge i_clk) begin
		if (i_rst) begin
			for (int i = 0; i < DEPTH; i++) begin
				mem[i] <= 8'h00;
			end
		end else if (i_we) begin
			case (i_width[1:0])
				2'b00: begin  // SB
					mem[baddr] <= i_data[7:0];
				end
				2'b01: begin  // SH
					mem[baddr]     <= i_data[7:0];
					mem[baddr + 1] <= i_data[15:8];
				end
				default: begin  // SW
					mem[baddr]     <= i_data[7:0];
					mem[baddr + 1] <= i_data[15:8];
					mem[baddr + 2] <= i_data[23:16];
					mem[baddr + 3] <= i_data[31:24];
				end
			endcase
		end
	end

	// Combinational read
	logic [7:0]  b0, b1, b2, b3;

	assign b0 = mem[baddr];
	assign b1 = mem[baddr + 1];
	assign b2 = mem[baddr + 2];
	assign b3 = mem[baddr + 3];

	always_comb begin
		case (i_width)
			3'b000: o_data = {{24{b0[7]}}, b0};          // LB  sign-extend
			3'b001: o_data = {{16{b1[7]}}, b1, b0};      // LH  sign-extend
			3'b010: o_data = {b3, b2, b1, b0};           // LW
			3'b100: o_data = {24'h000000, b0};            // LBU zero-extend
			3'b101: o_data = {16'h0000,   b1, b0};        // LHU zero-extend
			default: o_data = {b3, b2, b1, b0};
		endcase
	end

endmodule
