`timescale 10ps / 100fs

module loadUnit (
	input wire clock,

	input wire loadEnable,
	input wire[2:0] loadType,
	input wire[31:0] addr,
	input wire[5:0] robNum,

	output reg[31:0] addr_out,
	output reg readEnable,

	input wire[31:0] data_in,
		
	output reg cdbEnable,
	output reg[5:0] robNum_out,
	output reg[31:0] cdbdata,
	output reg busy
);

parameter LBOp = 3'b000;
parameter LHOp = 3'b001;
parameter LWOp = 3'b010;
parameter LBUOp = 3'b100;
parameter LHUOp = 3'b101;

initial begin
	cdbEnable = 1'b0;
	busy = 1'b0;
end

always @(posedge loadEnable) begin
	busy = 1'b1;
	cdbEnable = 1'b0;
	addr_out = addr;
	readEnable = 1'b1;
	#0.01
	robNum_out = robNum;
	//$display("readaddress in loadUnit = %d", addr_out);
	//$display("loadUnit data_in = %d", data_in);	
	case (loadType)
		LWOp: cdbdata = data_in; 
		LBOp: cdbdata = {{24{data_in[7:7]}}, data_in[7:0]}; 
		LHOp: cdbdata = {{16{data_in[15:15]}}, data_in[15:0]}; 
		LBUOp: cdbdata = {24'b0, data_in[7:0]};
		LHUOp: cdbdata = {16'b0, data_in[15:0]};
	endcase
	cdbEnable = 1'b1;
	busy = 1'b0;
	readEnable = 1'b0;
end

endmodule
