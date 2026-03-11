`timescale 1ns/1ps

module i_mem_tb;

// params
localparam MEM_SIZE 	= 1024;
localparam CLK_PERIOD 	= 10;

// dut signals
logic				clk;
logic				rst;
logic [$clog2(MEM_SIZE)-1:0]	addr;
logic [31 : 0]			ins;

// instantiate DUT
instruction_mem #(
	.MEM_SIZE(MEM_SIZE)
) dut (
	.i_clk(clk),
	.i_rst(rst),
	.i_addr(addr),
	.o_ins(ins)
);

// clock gen
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// tasks
task apply_reset();
	rst = 1;
	@(posedge clk); #1;
	rst = 0;
endtask

task read_addr(input logic [31:0] byte_addr, input logic [31:0] expected);
	addr = byte_addr;
	@(posedge clk); #1;
	if (ins === expected)
		$display("PASS | addr= 0x%08X | addr = 0x%08X", byte_addr, ins);
	else 
		$display("FAIL | addr=0x%08X | expected=0x%08X | got=0x%08X", byte_addr, expected, ins);
endtask

// test sequence
initial begin
	addr = 0;
	rst = 0;

	// Test 1: reset clears output
        $display("\nTest 1: Reset");
        rst = 1;
        @(posedge clk); #1;
        if (ins === 32'h0)
            $display("PASS | reset output is 0");
        else
            $display("FAIL | reset output expected 0, got 0x%08X", ins);
        rst = 0;
        @(posedge clk); #1;

        // Test 2: read each instruction (byte addresses 0x00 to 0x10)
        $display("\nTest 2: Sequential reads");
        read_addr(32'h00, 32'h00108113);
        read_addr(32'h04, 32'h00208193);
        read_addr(32'h08, 32'h00310233);
        read_addr(32'h0C, 32'hFE218AE3);
        read_addr(32'h10, 32'h00000000);

        // Test 3: re-read addr 0 to confirm no state corruption
        $display("\nTest 3: Re-read addr 0");
        read_addr(32'h00, 32'h00108113);

        // Test 4: reset mid-operation clears output
        $display("\nTest 4: Reset mid-operation");
        addr = 32'h08;
        apply_reset();
        if (ins === 32'h0)
            $display("PASS | output cleared on reset");
        else
            $display("FAIL | expected 0 after reset, got 0x%08X", ins);

        $display("\ndone");
        $finish;
end
endmodule
