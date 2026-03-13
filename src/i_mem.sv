`timescale 1ns/1ps

module instruction_mem #(
	parameter MEM_SIZE = 1024
)(
	input logic i_clk,
	input logic i_rst,
	input logic [$clog2(MEM_SIZE) - 1:0] i_addr,

	output logic [31 : 0] o_ins
);

	logic [31 : 0] mem [0:MEM_SIZE-1];
	
	initial begin
		$readmemh("tests.hex", mem);
	end

	assign o_ins = mem[i_addr >> 2];

endmodule
