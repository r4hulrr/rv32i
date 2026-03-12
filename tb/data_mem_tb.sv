`timescale 1ns/1ps

module data_mem_tb;

	localparam MEM_SIZE  = 1024;
	localparam CLK_PERIOD = 10;

	// DUT signals
	logic                        clk;
	logic                        rst;
	logic                        we;
	logic [31:0]                 data_in;
	logic [$clog2(MEM_SIZE)-1:0] addr;
	logic [31:0]                 data_out;

	// Instantiate DUT
	data_mem #(
		.MEM_SIZE(MEM_SIZE)
	) dut (
		.i_clk  (clk),
		.i_rst  (rst),
		.i_we   (we),
		.i_data (data_in),
		.i_addr (addr),
		.o_data (data_out)
	);

	// Clock gen
	initial clk = 0;
	always #(CLK_PERIOD/2) clk = ~clk;

	// Tasks
	task apply_reset();
		rst = 1; we = 0;
		@(posedge clk); #1;
		rst = 0;
	endtask

	task write_mem(
		input logic [$clog2(MEM_SIZE)-1:0] byte_addr,
		input logic [31:0]                 data
	);
		we      = 1;
		addr    = byte_addr;
		data_in = data;
		@(posedge clk); #1;
		we = 0;
	endtask

	task read_check(
		input logic [$clog2(MEM_SIZE)-1:0] byte_addr,
		input logic [31:0]                 expected,
		input string                       label
	);
		addr = byte_addr;
		#1;
		if (data_out === expected)
		    $display("PASS | %-30s | addr=0x%04X | got=0x%08X", label, byte_addr, data_out);
		else
		    $display("FAIL | %-30s | addr=0x%04X | expected=0x%08X | got=0x%08X",
			      label, byte_addr, expected, data_out);
	endtask

	// Tests
	initial begin

	rst = 0; we = 0; addr = 0; data_in = 0;

	//Test 1: reset clears memory
	$display("\nTest 1: Reset");
	// dirty memory first
	we = 1; addr = 10'h00; data_in = 32'hDEADBEEF;
	@(posedge clk); #1;
	we = 0;
	apply_reset();
	read_check(10'h00, 32'h0, "reset clears addr 0");
	read_check(10'h04, 32'h0, "reset clears addr 4");

	// Test 2: basic write then read
	$display("\nTest 2: Write/Read");
	write_mem(10'h00, 32'hDEADBEEF);
	read_check(10'h00, 32'hDEADBEEF, "write read addr 0x00");

	write_mem(10'h04, 32'hCAFEBABE);
	read_check(10'h04, 32'hCAFEBABE, "write read addr 0x04");

	write_mem(10'h08, 32'h12345678);
	read_check(10'h08, 32'h12345678, "write read addr 0x08");

	// Test 3: word alignment
	$display("\nTest 3: Word alignment");
	write_mem(10'h00, 32'hAAAAAAAA);
	// byte addresses 0,1,2,3 should all map to word 0
	read_check(10'h00, 32'hAAAAAAAA, "byte addr 0x00 -> word 0");
	read_check(10'h01, 32'hAAAAAAAA, "byte addr 0x01 -> word 0");
	read_check(10'h02, 32'hAAAAAAAA, "byte addr 0x02 -> word 0");
	read_check(10'h03, 32'hAAAAAAAA, "byte addr 0x03 -> word 0");

	// Test 4: write disabled
	$display("\nTest 4: Write disabled");
	we      = 0;
	addr    = 10'h10;
	data_in = 32'hFFFFFFFF;
	@(posedge clk); #1;
	read_check(10'h10, 32'h0, "we=0 no write");

	// Test 5: overwrite same address
	$display("\nTest 5: Overwrite");
	write_mem(10'h0C, 32'h11111111);
	read_check(10'h0C, 32'h11111111, "first write");
	write_mem(10'h0C, 32'h22222222);
	read_check(10'h0C, 32'h22222222, "overwrite same addr");

	// Test 6: reset clears written values
	$display("\nTest 6: Reset clears written values");
	write_mem(10'h14, 32'hBEEFCAFE);
	apply_reset();
	read_check(10'h14, 32'h0, "reset clears written value");

	$display("\nDone");
	$finish;
	end

endmodule
