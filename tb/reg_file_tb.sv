`timescale 1ns/1ps

module reg_file_tb;

	// Parameters
	localparam NUM_REG    = 32;
	localparam CLK_PERIOD = 10;

	// DUT signals
	logic                        clk;
	logic                        rst;
	logic                        we;
	logic [31:0]                 wr_data;
	logic [$clog2(NUM_REG)-1:0]  wr_addr;
	logic [$clog2(NUM_REG)-1:0]  rd1_addr;
	logic [$clog2(NUM_REG)-1:0]  rd2_addr;
	logic [31:0]                 rd1_data;
	logic [31:0]                 rd2_data;

	// Instantiate DUT
	reg_file #(
		.NUM_REG(NUM_REG)
	) dut (
		.i_clk      (clk),
		.i_rst      (rst),
		.i_we       (we),
		.i_wr       (wr_data),
		.i_wr_addr  (wr_addr),
		.i_rd1_addr (rd1_addr),
		.i_rd2_addr (rd2_addr),
		.o_rd1      (rd1_data),
		.o_rd2      (rd2_data)
	);

	// Clock gen
	initial clk = 0;
	always #(CLK_PERIOD/2) clk = ~clk;

	// tasks
	task apply_reset();
		rst = 1; we = 0;
		@(posedge clk); #1;
		rst = 0;
	endtask

	task write_reg(
		input logic [$clog2(NUM_REG)-1:0] addr,
		input logic [31:0]                data
	);
		we      = 1;
		wr_addr = addr;
		wr_data = data;
		@(posedge clk); #1;
		we = 0;
	endtask

	task read_check(
		input logic [$clog2(NUM_REG)-1:0] addr,
		input logic [31:0]                expected,
		input string                      label // we add label to know which test failed
	);
		// reads are combinational so just set addr and sample
		rd1_addr = addr;
		#1;
		if (rd1_data === expected)
		    $display("PASS | %s | addr=x%0d | got=0x%08X", label, addr, rd1_data);
		else
		    $display("FAIL | %s | addr=x%0d | expected=0x%08X | got=0x%08X", label, addr, expected, rd1_data);
	endtask

	// tests
	initial begin

	// init signals
	rst = 0; we = 0;
	wr_data = 0; wr_addr = 0;
	rd1_addr = 0; rd2_addr = 0;

	// Test 1: Reset clears all registers
	$display("\nTest 1: Reset");
	apply_reset();
	for (int i = 0; i < NUM_REG; i++) begin
	    read_check(i, 32'h0, "reset");
	end

	// Test 2: Basic write then read
	$display("\nTest 2: Basic write/read");
	write_reg(5'd1, 32'hDEADBEEF);
	read_check(5'd1, 32'hDEADBEEF, "write/read");

	write_reg(5'd2, 32'hCAFEBABE);
	read_check(5'd2, 32'hCAFEBABE, "write/read");

	// Test 3: x0 hardwired to 0
	$display("\nTest 3: x0 hardwired zero");
	write_reg(5'd0, 32'hFFFFFFFF);  // attempt write to x0
	read_check(5'd0, 32'h0, "x0 hardwired");

	// Test 4: simultaneous dual read
	$display("\nTest 4: Dual read");
	write_reg(5'd3, 32'hAAAAAAAA);
	write_reg(5'd4, 32'h55555555);
	rd1_addr = 5'd3;
	rd2_addr = 5'd4;
	@(posedge clk); #1;
	if (rd1_data === 32'hAAAAAAAA && rd2_data === 32'h55555555)
	    $display("PASS | dual read | rd1=0x%08X rd2=0x%08X", rd1_data, rd2_data);
	else
	    $display("FAIL | dual read | rd1=0x%08X rd2=0x%08X", rd1_data, rd2_data);

	// Test 5: write disabled (we=0)
	$display("\nTest 5: Write disabled");
	we      = 0;
	wr_addr = 5'd5;
	wr_data = 32'h12345678;
	@(posedge clk); #1;
	read_check(5'd5, 32'h0, "we=0 no write");

	// Test 6: reset clears written values
	$display("\nTest 6: Reset clears written values");
	write_reg(5'd10, 32'hBEEFCAFE);
	apply_reset();
	read_check(5'd10, 32'h0, "reset clears");

	$display("\nDone");
	$finish;
	end

endmodule
