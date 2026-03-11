module data_mem #(
	parameter MEM_SIZE = 1024
)(
	input logic i_clk,
	input logic i_rst,

	input logic i_we,
	input logic [31 : 0] i_data,
	input logic [$clog2(MEM_SIZE)-1:0] i_addr,

	output logic [31 : 0] o_data
);

	logic [31 : 0] mem [0 : MEM_SIZE - 1];

	always_ff @(posedge i_clk) begin
		if (i_rst) begin
			for(int i = 0; i < MEM_SIZE ; i++) begin
				mem[i] <= '0;
			end
		end else if (i_we) begin
			mem[i_addr >> 2] <= i_data;
		end
	end

	assign o_data = mem[i_addr >> 2];

endmodule
