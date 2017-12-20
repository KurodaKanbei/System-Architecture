`timescale 10ps / 100fs

module regstatus (
	input wire[4:0] reg1,
	input wire[4:0] reg2,

	input wire writeEnable,
	input wire[5:0] writedata,
	input wire[4:0] writeIndex,

	input wire[4:0] ROBindex,
	output reg[5:0] ROBstatus,

	output reg[5:0] q1,
	output reg[5:0] q2,

	input wire regStatusEnable,
	output reg funcUnitEnable
);

parameter invalidNum = 6'b010000;
reg[5:0] status[0:31];

integer i;

initial begin
	funcUnitEnable = 1'b0;
	for (i = 0; i < 32; i = i + 1) begin
		status[i] = invalidNum;
	end
	q1 = invalidNum;
	q2 = invalidNum;
end

always @(ROBindex) begin
	if (ROBstatus < 16) begin
		ROBstatus = status[ROBindex];
	end
	else ROBstatus = invalidNum;
end

always @(posedge writeEnable) begin
	status[writeIndex] = writedata;
	if (reg1 < 32) begin
		q1 = status[reg1];
	end 
	else q1 = invalidNum;
	if (reg2 < 32) begin
		q2 = status[reg2];
	end
	else q2 = invalidNum;
	if (ROBstatus < 16) begin
		ROBstatus = status[ROBindex];
	end
	else ROBstatus = invalidNum;
end

always @(posedge regStatusEnable) begin
	funcUnitEnable = 1'b0;
	if (reg1 < 32) begin
		q1 = status[reg1];
	end
	else q1 = invalidNum;
	if (reg2 < 32) begin
		q2 = status[reg2];
	end
	else q2 = invalidNum;

	#0.01
	funcUnitEnable = 1'b1;
end
endmodule
