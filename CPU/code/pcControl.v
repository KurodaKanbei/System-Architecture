`timescale 10ps / 100fs

module pcControl (
	input wire clock,
	input wire addempty,
	input wire lwempty,
	input wire swempty,
	input wire robempty,
	input wire bneempty,
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag,

	output reg available,
	output reg[31:0] pc,
	output reg decodePulse,

	input wire jump,
	input wire[31:0] jumppc,

	input wire pcChange,
	input wire[31:0] changeData
);

parameter bneOp = 7'b1100011;

integer count;

initial begin
	pc = {32{1'b1}};
	available = 1'b1;
	decodePulse = 1'b1;
	count = 100;
end

always @(posedge clock) begin
	if (count > 0) begin
		count = count - 1;	
	end else begin
		available = addempty & lwempty & swempty & robempty & bneempty;
		if (pcChange == 1'b1) begin
			pc = changeData - 1;
		end else 
		begin
			if (operatorType == bneOp) begin
				if (jump == 1) begin
					pc = jumppc - 1;
				end
			end
		end
		if (available == 1) begin
			decodePulse = 1'b0;
			pc = pc + 1;
			decodePulse = 1'b1;
		end
	end
end

endmodule
