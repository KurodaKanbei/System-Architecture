
`timescale 10ps / 100fs

module reorderBuffer (
	input wire clk,
	input wire[31:0] pcNumber, 
	input wire[6:0] issue_opType,
	input wire[2:0] issue_opSubType,
	input wire issue_opFlag,

	input wire[31:0] issue_data2,
	input wire[31:0] issue_pc,
	input wire[4:0] issue_destReg,
	input wire issueValid,

	input wire[5:0] adderIndexIn, 
	output reg[31:0] adderResult, 
	output reg adderReadyOut,

	input wire[5:0] loadIndexIn, 
	output reg[31:0] loadResult, 
	output reg loadReadyOut,
	
	input wire[5:0] storeIndexIn, 
	output reg[31:0] storeResult, 
	output reg storeReadyOut,
	
	input wire[5:0] bneIndexIn, 
	output reg[31:0] bneResult, 
	output reg bneReadyOut,
	
	output reg available,

	output reg statusWriteEnable, 
	output reg[4:0] statusWriteIndex, 
	output reg[5:0] statusWriteData,
	
	output reg[31:0] memoryReadAddr,

	output reg memoryWriteEnable, 
	output reg[31:0] memoryWriteData, 
	output reg[31:0] memoryWriteAddr,
	output reg[2:0] memoryWriteType,

	output reg[31:0] issueNewPC,
	output reg issueNewPCEnable,

	input wire storeEnable,
	input wire[5:0] storeRobIndex,
	input wire[31:0] storeDest,
	input wire[31:0] storeValue,

	input wire CDBisCast1, 
	input wire[5:0] CDBrobNum1, 
	input wire[31:0] CDBdata1,
	
	input wire CDBisCast2,
	input wire[5:0] CDBrobNum2,
	input wire[31:0] CDBdata2,

	output wire[5:0] space, // I think it is ugly

	output reg regWriteEnable,
	output reg[4:0] regWriteIndex,
	output reg[31:0] regWriteData,

	output reg[4:0] statusIndex,
	input wire[5:0] statusResult,
	
	input wire cataclysm,

	input wire[31:0] bneWriteResult,
	input wire bneWriteEnable,
	input wire[5:0] bneWriteIndex,

	output reg worldEnd,

	output reg nobranch,
	output reg nostore
);

parameter LUIOp = 7'b0110111;
parameter AUIPCOp = 7'b0010111;
parameter JALOp = 7'b1101111;
parameter JALROp = 7'b1100111;
parameter BneOp = 7'b1100011;
parameter LoadOp = 7'b0000011;
parameter StoreOp = 7'b0100011;
parameter CalcImmOp = 7'b0010011;
parameter CalcOp = 7'b0110011;
parameter FenceOp = 7'b0001111;
parameter Add = 3'b000;
parameter Sub = 3'b000;
parameter Sll = 3'b001;
parameter Slt = 3'b010;
parameter Sltu = 3'b011;
parameter Xor = 3'b100;
parameter Srl = 3'b101;
parameter Sra = 3'b101;
parameter Or = 3'b110;
parameter And = 3'b111;
parameter BEQOp = 3'b000;
parameter BNEOp = 3'b001;
parameter BLTOp = 3'b100;
parameter BGEOp = 3'b101;
parameter BLTUOp = 3'b110;
parameter BGEUOp = 3'b111;
parameter LBOp = 3'b000;
parameter LHOp = 3'b001;
parameter LWOp = 3'b010;
parameter LBUOp = 3'b100;
parameter LHUOp = 3'b101;
parameter SBOp = 3'b000;
parameter SHOp = 3'b001;
parameter SWOp = 3'b010;
parameter invalidNum = 6'b010000;
parameter Exception = 7'bxxxxxxx;

reg[6:0] optype[0:15];
reg[2:0] opsubtype[0:15];
reg opflag[0:15];

reg[31:0] value[0:15];
reg[31:0] dest[0:15];
reg ready[0:15];

reg stall;

reg[5:0] count, head, tail;

integer i;

initial begin 
	head = 6'b000000;
	tail = 6'b000000;
	issueNewPCEnable = 1'b0;
	regWriteEnable = 1'b0;
	statusWriteEnable = 1'b0;
	
	for (i = 0; i < 15; i = i + 1) begin
		optype[i] = 7'b0000000;
		opsubtype[i] = 3'b000;
		opflag[i] = 1'b0;
		value[i] = 32'h00000000;
		dest[i] = 32'h00000000;
		ready[i] = 1'b0;
	end
	count = 5'b00000;
	available = 1'b1;
	nobranch = 1'b1;
	nostore = 1'b1;
end

assign space = tail;

always @(posedge issueValid) begin
	#0.1
	statusWriteEnable = 1'b0;
	optype[tail] = issue_opType;
	opsubtype[tail] = issue_opSubType;
	ready[tail] = 1'b0;
	case(issue_opType)
		CalcOp, CalcImmOp: begin
			dest[tail] = {27'b0, issue_destReg};
			statusWriteIndex = issue_destReg;
			statusWriteData = tail;
			statusWriteEnable = 1'b1;
		end

		LUIOp, AUIPCOp: begin
			dest[tail] = {27'b0, issue_destReg};
			statusWriteIndex = issue_destReg;
			statusWriteData = tail;
			statusWriteEnable = 1'b1;
		end
		

		JALOp, JALROp: begin 
			dest[tail] = {27'b0, issue_destReg};
			statusWriteIndex = issue_destReg;
			statusWriteData = tail;
			statusWriteEnable = 1'b1;
			nobranch = 1'b0;
		end

		BneOp: begin
			nobranch = 1'b0;
		end

		LoadOp: begin
			dest[tail] = {27'b0, issue_destReg};
			statusWriteIndex = issue_destReg;
			statusWriteData = tail;
			statusWriteEnable = 1'b1;
		end

		StoreOp: begin
			nostore = 1'b0;
		end

		FenceOp: begin
			tail = tail - 1;	
		end

		Exception: begin
			ready[tail] = 1'b1;
		end

	endcase
	tail = tail + 1;
	if (tail >= 16) tail = 0;
	count = count + 1;
	if (count >= 16) available = 0;
end

always @(posedge clk) begin
	#100
	memoryWriteEnable = 1'b0;
	issueNewPCEnable = 1'b0;
	regWriteEnable = 1'b0;
	statusWriteEnable = 1'b0;
	issueNewPC = 1'b0;
	if (count > 0 && ready[head] == 1'b1) begin
		case(optype[head]) 
			CalcOp, CalcImmOp, LUIOp, AUIPCOp: begin
				statusIndex = dest[head][4:0];
				#0.01
				regWriteIndex = dest[head][4:0];
				regWriteData = value[head];
				regWriteEnable = 1'b1;
				if (statusResult == head) begin
					statusWriteIndex = dest[head][4:0];
					statusWriteData = 5'b10000;
					statusWriteEnable = 1'b1;
				end
			end

			JALOp, JALROp: begin
				statusIndex = dest[head][4:0];
				#0.01
				regWriteIndex = dest[head][4:0];
				regWriteData = pcNumber + 4;
				regWriteEnable = 1'b1;
				
				if (statusResult == head) begin
					statusWriteIndex = dest[head][4:0];
					statusWriteData = 5'b10000;
					statusWriteEnable = 1'b1;
				end
				
				issueNewPC = value[head];
				issueNewPCEnable = 1'b1;
				nobranch = 1'b1;
			end
			
			LoadOp: begin
				statusIndex = dest[head][4:0];
				#0.01
				regWriteIndex = dest[head][4:0];
				regWriteData = value[head];
				regWriteEnable = 1'b1;
			
				if (statusResult == head) begin
					statusWriteIndex = dest[head][4:0];
					statusWriteData = 5'b10000;
					statusWriteEnable = 1'b1;
				end
			end

			StoreOp: begin
				memoryWriteData = value[head];
				memoryWriteAddr = dest[head];
				memoryWriteType = opsubtype[head];
				memoryWriteEnable = 1'b1;
				nostore = 1'b1;
			end

			BneOp: begin
				issueNewPC = value[head];
				issueNewPCEnable = 1'b1;
				nobranch = 1'b1;
			end

			Exception: begin
				worldEnd = 1'b1;
			end

		endcase
		head = head + 1;
		count = count - 1;
		if (head >= 16) head = 0;
	end
	statusWriteEnable = 1'b0;
	regWriteEnable = 1'b0;
end

always @(adderIndexIn) begin
	if (adderIndexIn >= 16) begin
		adderResult = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
		adderReadyOut = 1'b0;
	end
	else begin
		adderResult = value[adderIndexIn];
		adderReadyOut = ready[adderIndexIn];
	end
end

always @(loadIndexIn) begin
	if (loadIndexIn >= 16) begin
		loadResult = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
		loadReadyOut = 1'b0;
	end
	else begin
		loadResult = value[loadIndexIn];
		loadReadyOut = ready[loadIndexIn];
	end
end

always @(storeIndexIn) begin
	if (storeIndexIn >= 16) begin
		storeResult = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;			
		storeReadyOut = 1'b0;
	end
	else begin
		storeResult = value[storeIndexIn];
		storeReadyOut = ready[storeIndexIn];
	end
end

always @(bneIndexIn) begin
	if (bneIndexIn >= 16) begin
		bneResult = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
		bneReadyOut = 1'b0;
	end
	else begin
		bneResult = value[bneIndexIn];
		bneReadyOut = ready[bneIndexIn];
	end
end

always @(posedge bneWriteEnable) begin
	if (bneWriteIndex < 16) begin
		value[bneWriteIndex] = bneWriteResult;
		ready[bneWriteIndex] = 1'b1;
	end
end

always @(posedge storeEnable) begin
	if (storeRobIndex < 16) begin
		dest[storeRobIndex] = storeDest;
		value[storeRobIndex] = storeValue;
		ready[storeRobIndex] = 1'b1;
	end
end

always @(posedge CDBisCast1) begin
	if (CDBrobNum1 < 16) begin
		value[CDBrobNum1] = CDBdata1;
		ready[CDBrobNum1] = 1'b1;
	end
end

always @(posedge CDBisCast2) begin
	if (CDBrobNum2 < 16) begin
		value[CDBrobNum2] = CDBdata2;
		ready[CDBrobNum2] = 1'b1;
	end
end

endmodule
