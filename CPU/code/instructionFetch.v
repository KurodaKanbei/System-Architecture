`timescale 10ps / 100fs

module instructionFetch (
	input wire[31:0] pc,
	input wire fetchPulse,

	output reg[31:0] instr,
	output reg isdone,
	
	input wire[31:0] instr_in,
	output reg[31:0] fetchAddr,
	output reg fetchEnable
); 

reg[31:0] mem[0:1000];

always @(posedge fetchPulse) begin
	fetchEnable = 1'b0;
	fetchAddr = pc;
	fetchEnable = 1'b1;
	#0.01
	instr = instr_in;
	if (instr[6:0] == 7'bxxxxxxx) begin
		isdone = 1'b1;
	end else begin
		isdone = 1'b0;
	end
	fetchEnable = 1'b0;
end

endmodule
