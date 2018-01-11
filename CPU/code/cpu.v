`timescale 10ps / 100fs

`include "pcControl.v"
`include "instructionFetch.v"
`include "instructionDecode.v"
`include "regfile.v"
`include "regstatus.v"
`include "addRS.v"
`include "loadRS.v"
`include "loadUnit.v"
`include "storeRS.v"
`include "bneRS.v"
`include "CDB.v"
`include "dataMemory.v"
`include "reorderBuffer.v"

module cpu();
	reg clock;
	wire exception;
	integer cycle;
	integer i, j, addr;
	
	initial begin
		cycle = 0;
		clock = 1'b0;
		$dumpfile("cpu.vcd");
		$dumpvars(2);
	
		#3200
		for (i = 0; i <= 8; i = i + 1) begin
			$display("reg[%d] = %h", i, regfile.mem[i]);
		end
		$finish;
	end
	
	always #100 begin
		clock = ~clock;

		if (clock == 0) cycle = cycle + 1;
	end
	
	assign exception = reorderBuffer.worldEnd;
	

	always @(posedge exception) begin
		for (i = 0; i < 8; i = i + 1) begin
			$display("reg[%d] = %h", i, regfile.mem[i]);
		end
		
		for (i = 0 + 4098; i < 32 + 4096; i = i + 1) begin
			$display("mem[%d] = %h", i, dataMemory.mem[i]);
		end
		$finish;
		
	end

	pcControl pcControl(
		.clock(clock),
		.addempty(addRS.available),
		.lwempty(loadRS.available),
		.swempty(storeRS.available),
		.robempty(reorderBuffer.available),
		.bneempty(bneRS.available),
		.nobranch(reorderBuffer.nobranch),
		.nostore(reorderBuffer.nostore),
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		.pcChange(reorderBuffer.issueNewPCEnable),
		.changeData(reorderBuffer.issueNewPC)
	);

	instructionFetch instructionFetch(
		.pc(pcControl.pc),
		.fetchPulse(pcControl.fetchPulse),
		.instr_in(dataMemory.instr_out)
	);

	instructionDecode instructionDecode(
		.clock(clock),
		.pcNumber(pcControl.pc),
		.decodePulse(pcControl.decodePulse),
		.instr(instructionFetch.instr),
		.available(pcControl.available)
	);

	regfile regfile(
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		
		.reg1(instructionDecode.reg1),
		.reg2(instructionDecode.reg2),
		.data1_in(instructionDecode.data1),
		.data2_in(instructionDecode.data2),
		
		.ROBwriteEnable(reorderBuffer.regWriteEnable),
		.ROBwriteData(reorderBuffer.regWriteData),
		.ROBwriteIndex(reorderBuffer.regWriteIndex),
		.regEnable(instructionDecode.regstatusEnable)
	);

	regstatus regstatus(
		.reg1(instructionDecode.reg1),
		.reg2(instructionDecode.reg2),
		
		.writeEnable(reorderBuffer.statusWriteEnable),
		.writedata(reorderBuffer.statusWriteData),
		.writeIndex(reorderBuffer.statusWriteIndex),

		.ROBindex(reorderBuffer.statusIndex),
		.regStatusEnable(instructionDecode.regstatusEnable)
	);

	addRS addRS(
		.clock(clock),
		.operatorType(instructionDecode.operatorType),	
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		
		.robNum(reorderBuffer.space),
		.data1(regfile.data1),
		.data2(regfile.data2),
		.q1(regstatus.q1),
		.q2(regstatus.q2),
		.offset_in(regfile.offset),

		.CDBiscast(CDBadd.iscast_out),
		.CDBrobNum(CDBadd.robNum_out),
		.CDBdata(CDBadd.data_out),
		.CDBiscast2(CDBlw.iscast_out),
		.CDBrobNum2(CDBlw.robNum_out),
		.CDBdata2(CDBlw.data_out),
		
		.ready(reorderBuffer.adderReadyOut),
		.value(reorderBuffer.adderResult),
		.funcUnitEnable(regstatus.funcUnitEnable)
	);

	loadRS loadRS(

		.clock(clock),
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		
		.data(regfile.data2),
		.q(regstatus.q1),
		.destRobNum(reorderBuffer.space),
		
		
		.cdbIscast(CDBadd.iscast_out),
		.cdbData(CDBadd.data_out),
		.cdbRobNum(CDBadd.robNum_out),
		.cdbIscast2(CDBlw.iscast_out),
		.cdbData2(CDBlw.data_out),
		.cdbRobNum2(CDBlw.robNum_out),
		
		.ready(reorderBuffer.loadReadyOut),
		.value(reorderBuffer.loadResult),
		
		.offset_in(regfile.offset),
		
		.busy(loadUnit.busy),
		
		.funcUnitEnable(regstatus.funcUnitEnable)
	);

	loadUnit loadUnit(
		.clock(clock),
		.addr(loadRS.data_out),
		.robNum(loadRS.robNum_out),	
		.loadType(loadRS.type_out),
		.data_in(dataMemory.data_out),
			
		.loadEnable(loadRS.loadEnable)
	);

	storeRS storeRS(
		.clock(clock),
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		
		.data1(regfile.data1),
		.q1(regstatus.q1),
		.data2(regfile.data2),
		.q2(regstatus.q2),
		
		.offset_in(regfile.offset),
		.destRobNum(reorderBuffer.space),
		
		.iscast(CDBadd.iscast_out),
		.cdbdata(CDBadd.data_out),
		.robNum(CDBadd.robNum_out),
		.iscast2(CDBlw.iscast_out),
		.cdbdata2(CDBlw.data_out),
		.robNum2(CDBlw.robNum_out),
		
		.ready(reorderBuffer.storeReadyOut),
		.value(reorderBuffer.storeResult),
		
		.funcUnitEnable(regstatus.funcUnitEnable)
	);

	bneRS bneRS(
		.clock(clock),
		.pcNumber(pcControl.pc),
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		.robNum(reorderBuffer.space),
		.data1(regfile.data1),
		.data2(regfile.data2),
		.q1(regstatus.q1),
		.q2(regstatus.q2),
		.offset_in(regfile.offset),

		.CDBiscast(CDBadd.iscast_out),
		.CDBrobNum(CDBadd.robNum_out),
		.CDBdata(CDBadd.data_out),
		.CDBiscast2(CDBlw.iscast_out),
		.CDBrobNum2(CDBlw.robNum_out),
		.CDBdata2(CDBlw.data_out),
		
		.ready(reorderBuffer.bneReadyOut),
		.value(reorderBuffer.bneResult),
		
		.funcUnitEnable(regstatus.funcUnitEnable)
	);

	CDB CDBadd(
		.enable(addRS.broadcast),
		.robNum(addRS.robNum_out),
		.data(addRS.data_out)
	);

	CDB CDBlw(
		.enable(loadUnit.cdbEnable),
		.robNum(loadUnit.robNum_out),
		.data(loadUnit.cdbdata)
	);

	dataMemory dataMemory(
		.clock(clock),
		.loadUnitreadAddr(loadUnit.addr_out),
		.loadUnitrequest(loadUnit.readEnable),
		
		.instrequest(instructionFetch.fetchEnable),
		.instreadAddr(instructionFetch.fetchAddr),
		.writeAddress(reorderBuffer.memoryWriteAddr),
		.writeRequest(reorderBuffer.memoryWriteEnable),
		.writeData(reorderBuffer.memoryWriteData),
		.writeType(reorderBuffer.memoryWriteType)

	);

	reorderBuffer reorderBuffer(
		.clk(clock),					
		.pcNumber(pcControl.pc),

		.issue_opType(instructionDecode.operatorType),
		.issue_opSubType(instructionDecode.operatorSubType),
		.issue_opFlag(instructionDecode.operatorFlag),
		.issue_data2(instructionDecode.data2), 
		.issue_destReg(instructionDecode.destreg),	
		.issueValid(instructionDecode.ROBissueValid),
		

		.adderIndexIn(addRS.index), 
		.loadIndexIn(loadRS.index), 
		.storeIndexIn(storeRS.index), 
		.bneIndexIn(bneRS.index),
	
		
		.storeEnable(storeRS.storeEnable), 
		.storeRobIndex(storeRS.robNum_out), 
		.storeDest(storeRS.data2_out), 
		.storeValue(storeRS.data1_out), 
		
		.CDBisCast1(CDBadd.iscast_out), 
		.CDBrobNum1(CDBadd.robNum_out), 
		.CDBdata1(CDBadd.data_out),
		
		.CDBisCast2(CDBlw.iscast_out), 
		.CDBrobNum2(CDBlw.robNum_out), 
		.CDBdata2(CDBlw.data_out),
		
		.statusResult(regstatus.ROBstatus),
		
		.cataclysm(instructionFetch.isdone),
		
		.bneWriteResult(bneRS.data_out), 
		.bneWriteEnable(bneRS.bneResultEnable), 
		.bneWriteIndex(bneRS.robNum_out)
	);

endmodule
