`timescale 10ps / 100fs

module instructionDecode(
	input wire clock,
	input wire decodePulse,
	input wire[31:0] instr,
	input wire available,

	output reg[6:0] operatorType,
	output reg[2:0] operatorSubType,
	output reg[6:0] operatorFlag,
	output reg[31:0] data1,
	output reg[31:0] data2,
	output reg[31:0] instr_out,
	output reg[4:0] reg1,
	output reg[4:0] reg2,
	output reg[4:0] destreg,

	output reg notfull,
	output reg ROBissueValid,
	output reg regstatusEnable
);

parameter LUIOp = 7'b0110111;
parameter AUIPCOp = 7'b0010111;
parameter JALOp = 7'b1101111;
parameter JALROp = 7'b1100111;
parameter BEQOp = 7'b1100111;
parameter LoadOp = 7'b0000011;
parameter StoreOp = 7'b0100011;
parameter CalcImmOp = 7'b0010011;
parameter CalcOp = 7'b0110011;
parameter FenceOp = 7'b0001111; 

reg ava;

initial begin
	ROBissueValid = 1'b0;
	regstatusEnable = 1'b0;
end

always @(posedge clock) begin
	ROBissueValid = 1'b0;
end

always @(posedge decodePulse) begin
	regstatusEnable = 1'b0;
	operatorType = 7'b1111111;
	operatorSubType = 3'b111;
	operatorFlag = 7'b1111111;
	ava = available;
	notfull = ava;
	if (ava == 1'b1) begin
		instr_out = instr;
		regstatusEnable = 1'b1;
		ROBissueValid = 1'b1;
		operatorType = instr[6:0];
		if (operatorType == LUIOp) begin
			destreg = instr[11:7];	
			data1 = instr[31:12];
		end
		if (operatorType == AUIPCOp) begin
			destreg = instr[11:7];	
			data1 = instr[31:12];		
		end
		if (operatorType == JALOp) begin
			destreg = instr[11:7];	
			data1 = instr[31:12];		
		end
		if (operatorType == JALROp) begin
			destreg = instr[11:7];	
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			data1 = instr[31:20];		
		end
		if (operatorType == BEQOp) begin
			data1 = instr[11:7];
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			reg2 = instr[24:20];
			data1 = instr[31:25];
		end
		if (operatorType == LoadOp) begin
			destreg = instr[11:7];
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			data1 = instr[31:20];
		end
		if (operatorType == StoreOp) begin
			data1 = instr[11:7];
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			reg2 = instr[24:20];
			data2 = instr[31:25];
		end
		if (operatorType == CalcImmOp) begin
			destreg = instr[11:7];
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			if (operatorSubType == 3'b001 || operatorSubType == 3'b101) begin
				data1 = instr[24:20];
				operatorFlag = instr[31:25];
			end else data1 = instr[31:20];
		end
		if (operatorType == CalcOp) begin
			destreg = instr[11:7];
			operatorSubType = instr[14:12];
			reg1 = instr[19:15];
			reg2 = instr[24:20];
			operatorFlag = instr[31:25];
		end
		if (operatorType == FenceOp) begin
			operatorSubType = instr[14:12];
			data1 = instr[23:20];
			data2 = instr[27:24];
		end
	end
end
endmodule