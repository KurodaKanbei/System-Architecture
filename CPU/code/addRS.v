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

`timescale 10ps / 100fs

module addRS (
	input wire clock,
	input wire[6:0] operatorType,
	input wire[2:0] operatorSubType,
	input wire operatorFlag, 
	input wire[5:0] robNum,
	input wire[31:0] data1,
	input wire[31:0] data2,
	input wire[5:0] q1,
	input wire[5:0] q2,
	input wire reset,

	input wire CDBiscast,
	input wire[5:0] CDBrobNum,
	input wire[31:0] CDBdata,

	input wire CDBiscast2,
	input wire[5:0] CDBrobNum2,
	input wire[31:0] CDBdata2,

	output reg[5:0] robNum_out,

	output reg[31:0] data_out,
	output reg broadcast,
	output reg available,

	output reg[5:0] index,
	input wire ready,
	input wire[31:0] value,

	input wire funcUnitEnable
);

parameter CalcImmOp = 7'b0010011;
parameter CalcOp = 7'b0110011;
parameter addi = 3'b000;
parameter slti = 3'b010;
parameter sltiu = 3'b011;
parameter xori = 3'b100;
parameter ori = 3'b110;
parameter andi = 3'b111;
parameter slli = 3'b001;
parameter srli = 3'b101;
parameter srai = 3'b101;
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
parameter invalidNum = 6'b010000;

reg[93:0] rs[0:3];

integer i;
reg breakmark;

initial begin
	broadcast = 1'b0;
	for (i = 0; i < 4; i = i + 1) begin
		rs[i] = {94{1'b0}};
	end
	available = 1'b1;
	index = invalidNum;
end

always@(posedge reset) begin
	broadcast = 1'b0;
	robNum_out = invalidNum;
	for (i = 0; i < 4; i = i + 1) begin
		rs[i][93:93] = 1'b0;
	end
	available = 1'b1;
end

always @(posedge CDBiscast or CDBiscast2) begin
	for (i = 0; i < 4; i = i + 1) begin
		if (rs[i][93:93] == 1'b1 && CDBiscast == 1'b1) begin
			if (rs[i][11:6] == CDBrobNum) begin
				rs[i][75:44] = CDBdata;
				rs[i][11:6] = invalidNum;
			end
			if (rs[i][5:0] == CDBrobNum) begin
				rs[i][43:12] = CDBdata;
				rs[i][5:0] =  invalidNum;
			end
		end
		if (rs[i][93:93] == 1'b1 && CDBiscast2 == 1'b1) begin
			if (rs[i][11:6] == CDBrobNum2) begin
				rs[i][75:44] = CDBdata2;
				rs[i][11:6] = invalidNum;
			end
			if (rs[i][5:0] == CDBrobNum2) begin
				rs[i][43:12] = CDBdata2;
				rs[i][5:0] =  invalidNum;
			end
		end
	end
end

always @(posedge clock) begin
	#50
	broadcast = 1'b0;
	breakmark = 1'b0;
	for (i = 0; i < 4; i = i + 1) begin
		if (rs[i][86:80] == CalcOp) begin
			if (rs[i][93:93] == 1'b1 && breakmark == 1'b0) begin
				if (rs[i][11:6] == invalidNum && rs[i][5:0] == invalidNum) begin
					robNum_out = rs[i][92:87];
					$display("CDB = index%d robNum%d", i, robNum_out);
					if (rs[i][79:77] == Add) begin
						if (rs[i][76:76] == 1'b0) data_out = rs[i][75:44] + rs[i][43:12]; else data_out = rs[i][75:44] - rs[i][43:12];
						$display("Data_out = %d", data_out);
					end
					if (rs[i][79:77] == Sll) begin
						data_out = rs[i][75:44] << rs[i][43:12];						
					end
					if (rs[i][79:77] == Slt) begin
						data_out = $signed(rs[i][75:44]) < $signed(rs[i][43:12]) ? 32'b1 : 32'b0;
					end
					if (rs[i][79:77] == Sltu) begin
						data_out = rs[i][75:44] < rs[i][43:12] ? 32'b1 : 32'b0;
					end
					if (rs[i][79:77] == Srl) begin
						if (rs[i][76] == 1'b0) data_out = rs[i][75:44] >> rs[i][43:12]; else data_out = $signed(rs[i][75:44]) >>> rs[i][43:12];
					end
					if (rs[i][79:77] == Xor) begin
						data_out = rs[i][75:44] ^ rs[i][43:12];
					end
					if (rs[i][79:77] == Or) begin
						data_out = rs[i][75:44] | rs[i][43:12];
					end
					if (rs[i][79:77] == And) begin
						data_out = rs[i][75:44] & rs[i][43:12];
					end
					broadcast = 1'b1;
					available = 1'b1;
					breakmark = 1'b1;
					rs[i][93:93] = 1'b0;
				end
			end
		end
		if (rs[i][86:80] == CalcImmOp) begin
			if (rs[i][93:93] == 1'b1 && breakmark == 1'b0) begin
				if (rs[i][11:6] == invalidNum && rs[i][5:0] == invalidNum) begin
					robNum_out = rs[i][92:87];
					$display("CDB = index%d robNum%d", i, robNum_out);
					if (rs[i][79:77] == Add) begin
						$display("Im doing Plus!!!!!!! Plus!!!!!!!!!!");
						$display("data1 %d && data2 %d", rs[i][75:44], rs[i][43:12]);
						$display("opFlag", rs[i][76:76]);
						data_out = rs[i][75:44] + rs[i][43:12]; 
					end
					if (rs[i][79:77] == Sll) begin
						data_out = rs[i][75:44] << rs[i][43:12];
					end
					if (rs[i][79:77] == Slt) begin
						data_out = $signed(rs[i][75:44]) < $signed(rs[i][43:12]) ? 32'b1 : 32'b0;
					end
					if (rs[i][79:77] == Sltu) begin
						data_out = rs[i][75:44] < rs[i][43:12] ? 32'b1 : 32'b0;
					end
					if (rs[i][79:77] == Srl) begin
						if (rs[i][76] == 1'b0) data_out = rs[i][75:44] >> rs[i][43:12]; else data_out = $signed(rs[i][75:44]) >>> rs[i][43:12];
					end
					if (rs[i][79:77] == Xor) begin
						data_out = rs[i][75:44] ^ rs[i][43:12];
					end
					if (rs[i][79:77] == Or) begin
						data_out = rs[i][75:44] | rs[i][43:12];
					end
					if (rs[i][79:77] == And) begin
						$display("^^^^^^^^^^^^^^^^^^^^^^^^^^^data1 = %d data2= %d", rs[i][75:44], rs[i][43:12]);
						data_out = rs[i][75:44] & rs[i][43:12];
						$display("data_out = %d", data_out);
					end
					broadcast = 1'b1;
					available = 1'b1;
					breakmark = 1'b1;
					rs[i][93:93] = 1'b0;
				end
			end
		end

	end
end

reg[31:0] data1_tmp;
reg[5:0] q1_tmp;
reg[31:0] data2_tmp;
reg[5:0] q2_tmp;

always @(posedge funcUnitEnable) begin
	if (operatorType == CalcOp || operatorType == CalcImmOp) begin
		//$display("robNum = %d", robNum);
		//$display("q1 = %d q2 = %d", q1, q2);
		//$display("data1 = %d &&&&&&& data2 = %d", data1, data2);

		index = q1;
		#0.01
		data1_tmp = data1;
		q1_tmp = q1;
		if (index < 16 && ready == 1'b1) begin
			data1_tmp = value;
			q1_tmp = invalidNum;
		end
		if (operatorType == CalcOp) begin
			index = q2;
			#0.01
			data2_tmp = data2;
			q2_tmp = q2;
			if (index < 16 && ready == 1'b1) begin
				data2_tmp = value;
				q2_tmp = invalidNum;
			end
		end else begin
			data2_tmp = data2;
			q2_tmp = invalidNum;
		end
		//$display("q1 = %d q2 = %d", q1, q2);
		//$display("data1_tmp = %d &&&&&&& data2_tmp = %d", data1_tmp, data2_tmp);
		$display("q1 = %d", q1);
		$display("q2 = %d", q2);
		breakmark = 1'b0;
		for (i = 0; i < 4; i = i + 1) begin
			if (rs[i][93:93] == 1'b0 && breakmark == 1'b0)  begin
				rs[i][93:93] = 1'b1;
				rs[i][92:87] = robNum;
				$display("robNum in addRS = %d", rs[i][92:87]);
				//$display("reservation index = %d", i);
				rs[i][86:80] = operatorType;
				rs[i][79:77] = operatorSubType;
				rs[i][76:76] = operatorFlag;
				rs[i][75:44] = data1_tmp;
				rs[i][43:12] = data2_tmp;
				//$display("reservation data1 = %d", rs[i][75:44]);
				//$display("reservation data2 = %d", rs[i][43:12]);
				rs[i][11:6] = q1_tmp;
				rs[i][5:0] = q2_tmp;
				//$display("reservation q1 = %d", rs[i][11:6]);
				//$display("reservation q2 = %d", rs[i][5:0]);
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
