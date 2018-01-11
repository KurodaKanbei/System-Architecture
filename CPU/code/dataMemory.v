`timescale 10ps / 100fs

module dataMemory (
	input wire clock,
	
	input wire[31:0] loadUnitreadAddr,
	input wire loadUnitrequest,
	output reg[31:0] data_out,
	

	input wire instrequest,
	input wire[31:0] instreadAddr,
	output reg[31:0] instr_out,

	input wire writeRequest,
	input wire[31:0] writeAddress,
	input wire[31:0] writeData,
	input wire[2:0] writeType
);

reg[7:0] mem[0:32767];
reg[31:0] instr[0:2048];

integer i;

parameter SBOp = 3'b000;
parameter SHOp = 3'b001;
parameter SWOp = 3'b010;

initial begin
	$readmemh("instr.bin", instr, 0);
	for (i = 0; i < 8192; i = i + 4) begin
		mem[i] = instr[i >> 2][31:24];
		mem[i + 1] = instr[i >> 2][23:16];
		mem[i + 2] = instr[i >> 2][15:8];
		mem[i + 3] = instr[i >> 2][7:0];
	end
end


always @(posedge writeRequest) begin
	if (writeRequest < 4096) begin
		if (writeAddress == 260) begin
			$display("%c", writeData);
		end
	end else begin
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
end

reg[31:0] readAddr;

always @(posedge loadUnitrequest) begin
	readAddr = loadUnitreadAddr;
	data_out = {mem[readAddr + 3], mem[readAddr + 2], mem[readAddr + 1], mem[readAddr]};
end

always @(posedge instrequest) begin
	readAddr = instreadAddr;
	instr_out = {mem[readAddr + 3], mem[readAddr + 2], mem[readAddr + 1], mem[readAddr]};
end

endmodule
