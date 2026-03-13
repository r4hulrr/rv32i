`timescale 1ns/1ps

module i_mem_tb;

// params
localparam MEM_SIZE 	= 1024;
localparam CLK_PERIOD 	= 10;

// dut signals
logic [$clog2(MEM_SIZE)-1:0]	addr;
logic [31 : 0]			ins;

// instantiate DUT
instruction_mem #(
	.MEM_SIZE(MEM_SIZE)
) dut (
	.i_addr(addr),
	.o_ins(ins)
);

// clock gen
task read_addr(input logic [31:0] byte_addr, input logic [31:0] expected);
	addr = byte_addr;
	#1;
	if (ins === expected)
		$display("PASS | addr= 0x%08X | addr = 0x%08X", byte_addr, ins);
	else 
		$display("FAIL | addr=0x%08X | expected=0x%08X | got=0x%08X", byte_addr, expected, ins);
endtask

// test sequence
initial begin
	addr = 0;
	#5;

	$display("\nSequential reads");
	read_addr(32'h00, 32'h00108113);
	read_addr(32'h04, 32'h00208193);
	read_addr(32'h08, 32'h00310233);
	read_addr(32'h0C, 32'hFE218AE3);
	read_addr(32'h10, 32'h00000000);

	$display("\nRe-read addr 0");
	read_addr(32'h00, 32'h00108113);

	$display("\nDone");
	$finish;
end
endmodule

