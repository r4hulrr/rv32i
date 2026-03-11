module reg_file #(
	parameter NUM_REG = 32
)(
	// clk and reset
	input logic i_clk,
	input logic i_rst,

	// writing 
	input logic i_we,
	input logic [31 : 0] i_wr,
	input logic [$clog2(NUM_REG)-1 : 0] i_wr_addr,

	// reading
	input logic [$clog2(NUM_REG)-1 : 0] i_rd1_addr,
	input logic [$clog2(NUM_REG)-1 : 0] i_rd2_addr,

	// output
	output logic [31 : 0] o_rd1,
	output logic [31 : 0] o_rd2
);

	logic [31:0] reg_mem [0:NUM_REG-1];

	always_ff @(posedge i_clk) begin
		if (i_rst) begin
			:for (int i = 0; i < NUM_REG; i++) begin
                		reg_mem[i] <= '0;
			end
        	end else if (i_we && i_wr_addr != 0) begin  // x0 hardwired to 0
			reg_mem[i_wr_addr] <= i_wr;
        	end
    	end

    // combinational reads, always available
	assign o_rd1 = (i_rd1_addr == 0) ? '0 : reg_mem[i_rd1_addr];
	assign o_rd2 = (i_rd2_addr == 0) ? '0 : reg_mem[i_rd2_addr];	 

endmodule
