`timescale 10ps / 100fs

module pcControl (
	input wire clock,
	input wire addempty,
	input wire lwempty,
	input wire swempty,
	input wire robempty,
	input wire bneempty,
	input wire nobranch,
	input wire nostore,
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,

	output reg available,
	output reg[31:0] pc,
	output reg decodePulse,
	output reg fetchPulse,

	input wire pcChange,
	input wire[31:0] changeData
);

parameter bneOp = 7'b1100011;

assign nobrach = 1'b1;

initial begin
	pc = -4;
	available = 1'b1;
	decodePulse = 1'b1;
end

always @(posedge pcChange) begin
	pc = changeData;
end

always @(posedge clock) begin
	available = addempty & lwempty & swempty & robempty & bneempty & nobranch & nostore;
	if (available == 1) begin
		fetchPulse = 1'b0;
		pc = pc + 4;
		$display("PCnumber = %d", pc);
		fetchPulse = 1'b1;
		#1
		decodePulse = 1'b0;
		decodePulse = 1'b1;
	end
end

endmodule
