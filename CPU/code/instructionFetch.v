`timescale 10ps / 100fs

module instructionFetch (
	input wire[31:0] pc,
	output reg[31:0] instr,
	output reg isdone
); 

parameter size = 1 << 7;
reg[31:0] mem [0:size - 1];
integer i;	

initial begin
	$readmemb("instruction.bin", mem, 0);
	for (i = 0; i < size; i = i + 1) begin
		//mem[i] = {mem[i][7:0] | mem[i][15:8] | mem[i][23:16] | mem[i][31:24]};		
	end
	isdone = 0;
end

always @(pc) begin
	instr = mem[pc];
	if (instr[6:0] == 7'bxxxxxxx) begin
		isdone = 1'b1;
	end else begin
		isdone = 1'b0;
	end
end

endmodule
