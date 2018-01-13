`timescale 10ps / 100fs
/*
	55:55 busy
	54:49 dest
	48:42 operatorType
	41:39 operatorSubType
	38:38 operatorFlag
	37:6 data
	5:0 q
*/
module loadRS (
	input wire clock,
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,
	input wire[31:0] data,
	input wire[5:0] q,
	input wire[5:0] destRobNum,

	output reg[5:0] robNum_out,
	output reg[2:0] type_out,
	output reg[31:0] data_out,
	output reg available,

	input wire cdbIscast,
	input wire[31:0] cdbData,
	input wire[5:0] cdbRobNum,
	
	input wire cdbIscast2,
	input wire[31:0] cdbData2,
	input wire[5:0] cdbRobNum2,

	output reg[5:0] index,

	input wire ready,
	input wire[31:0] value,
	input wire[31:0] offset_in,
	input wire busy,

	input wire funcUnitEnable,
	output reg loadEnable
);

parameter loadOp = 7'b0000011;
parameter LBOp = 3'b000;
parameter LHOp = 3'b001;
parameter LWOp = 3'b010;
parameter LBUOp = 3'b100;
parameter LHUOp = 3'b101;
parameter invalidNum = 6'b010000;

reg[55:0] rs[0:3];
reg[31:0] offset[0:3];
reg[5:0] robNum[0:3];
integer i;

initial begin
	for (i = 0; i < 4; i = i + 1) begin
		rs[i] = {56{1'b0}};
		offset[i] = 32'b0;
		robNum[i] = 6'b0;
	end
	available = 1'b1;
	loadEnable = 1'b0;
end

reg breakmark;

always @(posedge cdbIscast or posedge cdbIscast2) begin
	for (i = 0; i < 4; i = i + 1) begin
		if (rs[i][55:55] == 1'b1 && cdbIscast == 1'b1 && rs[i][5:0] == cdbRobNum) begin
		rs[i][37:6] = cdbData;
		rs[i][5:0] = invalidNum;
	end
		if (rs[i][55:55] == 1'b1 && cdbIscast == 1'b1 && rs[i][5:0] == cdbRobNum2) begin
			rs[i][37:6] = cdbData2;
			rs[i][5:0] = invalidNum;
		end
	end
end

reg[31:0] data_tmp;
reg[5:0] q_tmp;

always @(posedge clock) begin
	#50
	breakmark = 1'b0;
	loadEnable = 1'b0;
	for (i = 0;i < 4; i = i + 1) begin
		if (rs[i][55:55] == 1'b1 && breakmark == 1'b0 && busy == 1'b0) begin
			if (rs[i][5:0] == invalidNum) begin
				data_out = rs[i][37:6] + offset[i];
				type_out = rs[i][41:39];
				robNum_out = robNum[i];
				rs[i][55:55] = 1'b0;
				available = 1'b1;
				breakmark = 1'b1;
				loadEnable = 1'b1;
			end
		end
	end
	loadEnable = 1'b0;
end

always @(posedge funcUnitEnable) begin
	if (operatorType == loadOp) begin
		index = q;
		#0.01
		data_tmp = data;
		q_tmp = q;
		if (index < 16 && ready == 1'b1) begin
			data_tmp = value;
			q_tmp = invalidNum;
		end
		index = invalidNum;
		breakmark = 1'b0;
		for (i = 0; i < 4; i = i + 1) begin
			if (rs[i][55:55] == 1'b0 && breakmark == 1'b0) begin

				robNum[i] = destRobNum;
				offset[i] = offset_in;
				rs[i][55:55] = 1'b1;
				rs[i][48:42] = operatorType;
				rs[i][41:39] = operatorSubType;
				rs[i][38:38] = operatorFlag;
				rs[i][37:6] = data_tmp;
				rs[i][5:0] = q_tmp;
				breakmark = 1'b1;
			end
			available = 1'b0;
			breakmark = 1'b0;
			for (i = 0; i < 4; i = i + 1) begin
				if (rs[i][55:55] == 1'b0 && breakmark == 1'b0) begin
						available = 1'b1;
						breakmark = 1'b1;
					end
			end
		end
	end
end
endmodule
