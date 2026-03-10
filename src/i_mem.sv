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

	always_ff @(posedge i_clk) begin
		if(i_rst) begin
			o_ins <= '0;
		end else begin
			// word aligned
			o_ins <= mem[i_addr >> 2];
		end
	end

endmodule
