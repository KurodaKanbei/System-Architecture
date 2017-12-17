`timescale 10ps / 100fs

module instructionFetch (
	input wire[31:0] pc,
	output reg[31:0] instr,
	output reg isdone
); 

parameter size = 1 << 7;

reg [31:0] mem[0:size - 1];

integer i;

initial begin
	$readmemb("instruction", mem, 0);
	isdone = 0;
end

always @(pc) begin
	instr = mem[pc];
	if (instr[31:26] == 6'b111111) begin
		isdone = 1'b1;
	end else begin
		isdone = 1'b0;
	end
end

endmodule
