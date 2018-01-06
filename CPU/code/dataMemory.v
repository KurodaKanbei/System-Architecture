`timescale 10ps / 100fs

module dataMemory (
	input wire clock,
	input wire[31:0] loadUnitreadAddr,
	input wire loadUnitrequest,
	output reg[31:0] data_out,
	

	input wire writeRequest,
	input wire[31:0] writeAddress,
	input wire[31:0] writeData,
	input wire[2:0] writeType
);

reg[7:0] mem[0:1023];

integer i;

parameter SBOp = 3'b000;
parameter SHOp = 3'b001;
parameter SWOp = 3'b010;

initial begin 
	for (i = 0; i < 1024; i = i + 1) begin
		mem[i] = {8{1'b0}};
	end
end


always @(posedge writeRequest) begin
	/*$display("memory Write is coming!!!!!");
	$display("Address = %d", writeAddress);
	$display("Data = %d", writeData);
	$display("WriteType = %b", writeType);*/
	if (writeType == SBOp) begin
		mem[writeAddress] = writeData[7:0];
	end
	if (writeType == SHOp) begin
		mem[writeAddress] = writeData[7:0];
		mem[writeAddress + 1] = writeData[15:8];
	end
	if (writeType == SWOp) begin
		mem[writeAddress] = writeData[7:0];
		mem[writeAddress + 1] = writeData[15:8];
		mem[writeAddress + 2] = writeData[23:16];
		mem[writeAddress + 3] = writeData[31:24];
	end
end

reg[31:0] readAddr;

always @(posedge loadUnitrequest) begin
	readAddr = loadUnitreadAddr;
	data_out = {mem[readAddr + 3], mem[readAddr + 2], mem[readAddr + 1], mem[readAddr]};
	$display("load_Unit out = %b", data_out);
end

endmodule
