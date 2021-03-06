`timescale 10ps / 100fs

/*
	93:93 busy
	92:87 dest
	86:80 operator
	79:77 subtype
	76:76 flag
	75:44 data1
	43:12 data2
	11:6 q1
	5:0 q2
*/

module bneRS (
	input wire clock,
	input wire[31:0] pcNumber,

	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,

	input wire[5:0] robNum,
	input wire[31:0] data1,
	input wire[31:0] data2,
	input wire[5:0] q1,
	input wire[5:0] q2,
	input wire[31:0] offset_in,

	input wire CDBiscast,
	input wire[5:0] CDBrobNum,
	input wire[31:0] CDBdata,
	
	input wire CDBiscast2,
	input wire[5:0] CDBrobNum2,
	input wire[31:0] CDBdata2,
	
	output reg[5:0] robNum_out,
	
	output reg bneResultEnable,
	output reg[31:0] data_out,
	output reg available,
	
	output reg[5:0] index,
	input wire ready,
	input wire[31:0] value,
	input wire funcUnitEnable
);

parameter bneOp = 7'b1100011;
parameter JALOp = 7'b1101111;
parameter JALROp = 7'b1100111;
parameter invalidNum = 6'b010000;
parameter BEQOp = 3'b000;
parameter BNEOp = 3'b001;
parameter BLTOp = 3'b100;
parameter BGEOp = 3'b101;
parameter BLTUOp = 3'b110;
parameter BGEUOp = 3'b111;

reg[93:0] rs[0:3];
reg[31:0] offset[0:3];

integer i;
reg breakmark;

initial begin
	bneResultEnable = 1'b0;
	for (i = 0; i < 4; i = i + 1) begin
		rs[i] = {94{1'b0}};
	end
	available = 1'b1;
	index = invalidNum;
end

always @(posedge CDBiscast or posedge CDBiscast2) begin
	for (i = 0; i < 4; i = i + 1) begin
		if (rs[i][93:93] == 1'b1 && CDBiscast == 1'b1) begin
			if (rs[i][11:6] == CDBrobNum) begin
				rs[i][75:44] = CDBdata;
				rs[i][11:6] = invalidNum; 
			end
			if (rs[i][5:0] == CDBrobNum) begin
				rs[i][43:12] = CDBdata;
				rs[i][5:0] = invalidNum;
			end
		end
		if (rs[i][93:93] == 1'b1 && CDBiscast2 == 1'b1) begin
			if (rs[i][11:6] == CDBrobNum2) begin
				rs[i][75:44] = CDBdata2;
				rs[i][11:6] = invalidNum; 
			end
			if (rs[i][5:0] == CDBrobNum2) begin
				rs[i][43:12] = CDBdata2;
				rs[i][5:0] = invalidNum;
			end
		end
	end
end

parameter Taken = 32'b1;
parameter notTaken = 32'b0;
reg taken;

always @(posedge clock) begin
	#50
	breakmark = 1'b0;
	bneResultEnable = 1'b0;
	for (i = 0; i < 4; i = i + 1) begin
		if (rs[i][93:93] == 1'b1  && breakmark == 1'b0) begin
			if (rs[i][11:6] == invalidNum && rs[i][5:0] == invalidNum) begin
				rs[i][93:93] = 1'b0;
				if (rs[i][86:80] == bneOp) begin
					case (rs[i][79:77])
						BEQOp: if (rs[i][75:44] == rs[i][43:12]) taken = Taken; else taken = notTaken;
						BNEOp: if (rs[i][75:44] == rs[i][43:12]) taken = notTaken; else taken = Taken;
						BLTOp: if ($signed(rs[i][75:44]) < $signed(rs[i][43:12])) taken = Taken; else taken = notTaken;
						BGEOp: if ($signed(rs[i][75:44]) < $signed(rs[i][43:12])) taken = notTaken; else taken = Taken; 
						BLTUOp:	if (rs[i][75:44] < rs[i][43:12]) taken = Taken; else taken = notTaken; 
						BGEUOp: if (rs[i][75:44] < rs[i][43:12]) taken = notTaken; else taken = Taken;
					endcase
					if (taken == Taken) data_out = pcNumber + offset[i] - 4; else data_out = pcNumber; 
				end else begin
					if (operatorType == JALOp) data_out = pcNumber + offset[i] - 4; else data_out = rs[i][75:44] + offset[i] - 4;	
				end
				robNum_out = rs[i][92:87];
				bneResultEnable = 1'b1;
				available = 1'b1;
				breakmark = 1'b1;
			end
		end
	end
end

reg[31:0] data1_tmp;
reg[5:0] q1_tmp;
reg[31:0] data2_tmp;
reg[5:0] q2_tmp;

always @(posedge funcUnitEnable) begin
	if (operatorType == bneOp || operatorType == JALOp || operatorType == JALROp) begin
		if (operatorType == bneOp || operatorType == JALROp) begin
			index = q1;
			#0.01
			data1_tmp = data1;
			q1_tmp = q1;
			if (index < 16 && ready == 1'b1) begin
				data1_tmp = value;
				q1_tmp = invalidNum;
			end
		end else begin
			q1_tmp = invalidNum;
			data1_tmp = 32'h00000000; 
		end
		if (operatorType == bneOp) begin
			index = q2;
			#0.01
			data2_tmp = data2;
			q2_tmp = q2;
			if (index < 16 && ready == 1'b1) begin
				data2_tmp = value;
				q2_tmp = invalidNum;
			end
		end else begin
			q2_tmp = invalidNum;
			data2_tmp = 32'h00000000;
		end
		index = invalidNum;
		breakmark = 1'b0;
		for (i = 0; i < 4; i = i + 1) begin
			if (rs[i][93:93] == 1'b0 && breakmark == 1'b0) begin
				offset[i] = offset_in;
				rs[i][93:93] = 1'b1;
				rs[i][92:87] = robNum;
				rs[i][86:80] = operatorType;
				rs[i][79:77] = operatorSubType;
				rs[i][76:76] = operatorFlag;
				rs[i][75:44] = data1_tmp;
				rs[i][43:12] = data2_tmp;
				rs[i][11:6] = q1_tmp;
				rs[i][5:0] = q2_tmp;
				breakmark = 1'b1;
			end
		end
		available = 1'b0;
		for (i = 0; i < 4; i = i + 1) begin
			if (rs[i][93:93] == 1'b0) begin
				available = 1'b1;
			end
		end
	end
end
endmodule
