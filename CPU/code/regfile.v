`timescale 10ps /100fs

module regfile (
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,

	input wire[5:0] reg1,
	input wire[5:0] reg2,
	input wire[31:0] data1_in,
	input wire[31:0] data2_in,

	

);
