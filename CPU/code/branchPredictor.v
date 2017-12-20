`timescale 10ps / 100fs

module branchPredictor (
	input wire branchWriteEnable,
	input wire[1:0] branchWriteData,
	input wire[31:0] branchWriteAddr,

	input wire[31:0] branchPCReadAddr, 
	output reg branchPCPredict,
	
	input wire[31:0] branchROBReadAddr,
	output reg[1:0] branchROBPredict
);
parameter size = 1 << 10;
reg[1:0] perAddr0[0:size - 1], perAddr1[0:size - 1], perAddr2[0:size - 1], perAddr3[0:size - 1];
reg[1:0] global[0:1];

integer i;
initial begin
	for (i = 0; i < size; i = i + 1) begin
		perAddr0[i] = 2'b00;
		perAddr1[i] = 2'b00;
		perAddr2[i] = 2'b00;
		perAddr3[i] = 2'b00;
	end
	global[0] = 2'b00;
	global[1] = 2'b00;
end

always @(branchPCReadAddr or branchROBReadAddr) begin
	if (global[0] <= 1) begin
		if (global[1] <= 1) begin
			branchPCPredict = perAddr0[branchPCReadAddr][1:1];
			branchROBPredict = perAddr0[branchROBReadAddr];
		end
		else begin
			branchPCPredict = perAddr2[branchPCReadAddr][1:1];
			branchROBPredict = perAddr2[branchROBReadAddr];
		end
	end
	else begin
		if (global[1] <= 1) begin
			branchPCPredict = perAddr1[branchPCReadAddr][1:1];
			branchROBPredict = perAddr1[branchROBReadAddr];
		end
		else begin
			branchPCPredict = perAddr3[branchPCReadAddr][1:1];
			branchROBPredict = perAddr3[branchROBReadAddr];
		end
	end
end

always @(posedge branchWriteEnable) begin
	if (global[0] <= 1) begin
		if (global[1] <= 1) begin
			perAddr0[branchWriteAddr] = branchWriteData;
		end
		else begin
			perAddr2[branchWriteAddr] = branchWriteData;
		end
	end
	else begin
		if (global[1] <= 1) begin
			perAddr1[branchWriteAddr] = branchWriteData;
		end
		else begin
			perAddr3[branchWriteAddr] = branchWriteData;
		end
	end
	global[1] = global[0];
	global[0] = branchWriteData;
	
	if (global[0] <= 1) begin
		if (global[1] <= 1) begin
			branchPCPredict = perAddr0[branchPCReadAddr][1:1];
			branchROBPredict = perAddr0[branchROBReadAddr];
		end
		else begin
			branchPCPredict = perAddr2[branchPCReadAddr][1:1];
			branchROBPredict = perAddr2[branchROBReadAddr];
		end
	end
	else begin
		if (global[1] <= 1) begin
			branchPCPredict = perAddr1[branchPCReadAddr][1:1];
			branchROBPredict = perAddr1[branchROBReadAddr];
		end
		else begin
			branchPCPredict = perAddr3[branchPCReadAddr][1:1];
			branchROBPredict = perAddr3[branchROBReadAddr];
		end
	end
end
endmodule
