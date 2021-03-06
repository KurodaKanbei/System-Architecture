`timescale 10ps /100fs

module regfile (
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,

	input wire[4:0] reg1,
	input wire[4:0] reg2,
	input wire[31:0] data1_in,
	input wire[31:0] data2_in,

	input wire ROBwriteEnable,
	input wire[31:0] ROBwriteData,
	input wire[4:0] ROBwriteIndex,

	output reg[31:0] data1,
	output reg[31:0] data2,
	output reg[31:0] offset,

	input wire regEnable
);

parameter CalcImmOp = 7'b0010011;
parameter CalcOp = 7'b0110011;
parameter LuiOp = 7'b0110111;
parameter AiopcOp = 7'b0010111;
parameter JalOp = 7'b1101111;
parameter JalROp = 7'b1100111;
parameter BneOp = 7'b1100011;
parameter LoadOp = 7'b0000011;
parameter StoreOp = 7'b0100011;
parameter FenceOp = 7'b0001111;
parameter JALOp = 7'b1101111;
parameter JALROp = 7'b1100111;
parameter LUIOp = 7'b0110111;
parameter AUIPCOp = 7'b0010111;

reg[31:0] mem[0:31];

integer i;

initial begin
	for (i = 0; i < 32; i = i + 1) begin
		mem[i] = {32{1'b0}};
	end
end

always @(posedge regEnable) begin
	offset = 0;
	if (operatorType == CalcOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
	end
	if (operatorType == CalcImmOp) begin
		data1 = mem[reg1];
		data2 = data2_in;
	end
	if (operatorType == LoadOp) begin
		data2 = mem[reg1];
		offset = data2_in;	
	end
	if (operatorType == StoreOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
		offset = data2_in;
	end
	if (operatorType == BneOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
		offset = data2_in;
	end
	if (operatorType == LUIOp || operatorType == AUIPCOp) begin
		offset = data2_in;
	end
	if (operatorType == JALOp) begin
		offset = data2_in;	
	end
	if (operatorType == JALROp) begin
		data1 = mem[reg1];
		offset = data2_in;
	end
end

always @(posedge ROBwriteEnable) begin
	//$display("ROB -> regfile:Index %d", ROBwriteIndex);
	//$display("ROB -> regfile:Data %d", ROBwriteData);
	if (ROBwriteIndex > 0) mem[ROBwriteIndex] = ROBwriteData;
	/*offset = 0;
	if (operatorType == CalcImmOp) begin
		data1 = mem[reg1];
		data2 = data2_in;
	end
	if (operatorType == CalcOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
	end
	if (operatorType == StoreOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
		offset = data2_in;
	end
	if (operatorType == BneOp) begin
		data1 = mem[reg1];
		data2 = mem[reg2];
		offset = data2_in;
	end
	if (operatorType == LUIOp || operatorType == AUIPCOp) begin
		data1 = data1_in;
		data2 = data2_in;
	end*/
end

endmodule
