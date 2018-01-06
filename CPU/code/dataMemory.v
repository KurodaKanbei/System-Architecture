`timescale 10ps / 100fs

module dataMemory (
	input wire clock,
	input wire[31:0] readAddr,
	output reg[31:0] loadUnit_out,

	input wire[31:0] readAddress,
	output reg readEnable,
	output reg[31:0] data_out,

	input wire[31:0] writeAddress,
	input wire writeRequest,
	input wire[31:0] writeData,
	input wire[2:0] writeType,
	output reg writeDone
);

reg[7:0] mem[0:1023];

reg[31:0] readAddrOffset;
reg[31:0] writeAddrOffset;
reg[5:0] writeWordOffset;

parameter countNum = 1;

integer i, j;

initial begin 
	for (i = 0; i < 1024; i = i + 1) begin
		mem[i] = {8{1'b0}};
	end
end

initial begin
	writeDone = 1'b1;
	readEnable = 1'b1;
end

always @(posedge writeRequest) begin
	writeDone = 1'b0;
	writeAddrOffset = writeAddress;
end

always @(posedge readAddress) begin
	readEnable = 1'b0;
	readAddrOffset = readAddress;
end

always @(posedge readAddr) begin
	loadUnit_out = {mem[readAddr + 3], mem[readAddr + 2], mem[readAddr + 1], mem[readAddr]};
end

always @(posedge clock) begin
	if (writeDone == 0) begin
		writeDone = 1'b1;
	end
	if (readEnable == 0) begin
		data_out = {mem[readAddrOffset + 3], mem[readAddrOffset + 2], mem[readAddrOffset + 1], mem[readAddrOffset]};
		readEnable = 1'b1;
	end
end
endmodule
