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
`include "dataCache.v"
`include "dataMemory.v"
`include "reorderBuffer.v"
`include "branchPredictor.v"

module cpu();
	reg clock;
	wire exception;
	integer cycle;
	
	initial begin
		cycle = 0;
		clock = 1'b0;
		$dumpfile("cpu.vcd");
		$dumpvars(2);

		#3000
		$finish;
	end
	
	always #100 begin
		clock = ~clock;
		if (clock == 0) cycle = cycle + 1;
		//$display("%d", pcControl.pc);
	end
	
	assign exception = reorderBuffer.worldEnd;
	
	integer i, j, addr;

	always @(posedge exception) begin
		
		/*for (i = 0; i <= 6; ++i) begin
			$display("\n");
			$display("Memory block %h", i);
			$display("");
			addr = i * 64;
			$display("%h: %x", addr + 0 * 4, dataMemory.mem[i][32 * 0 + 31:32 * 0]);
			$display("%h: %x", addr + 1 * 4, dataMemory.mem[i][32 * 1 + 31:32 * 1]);
			$display("%h: %x", addr + 2 * 4, dataMemory.mem[i][32 * 2 + 31:32 * 2]);
			$display("%h: %x", addr + 3 * 4, dataMemory.mem[i][32 * 3 + 31:32 * 3]);
			$display("%h: %x", addr + 4 * 4, dataMemory.mem[i][32 * 4 + 31:32 * 4]);
			$display("%h: %x", addr + 5 * 4, dataMemory.mem[i][32 * 5 + 31:32 * 5]);
			$display("%h: %x", addr + 6 * 4, dataMemory.mem[i][32 * 6 + 31:32 * 6]);
			$display("%h: %x", addr + 7 * 4, dataMemory.mem[i][32 * 7 + 31:32 * 7]);
			
			$display("%h: %x", addr + 8 * 4, dataMemory.mem[i][32 * 8 + 31:32 * 8]);
			$display("%h: %x", addr + 9 * 4, dataMemory.mem[i][32 * 9 + 31:32 * 9]);
			$display("%h: %x", addr + 10 * 4, dataMemory.mem[i][32 * 10 + 31:32 * 10]);
			$display("%h: %x", addr + 11 * 4, dataMemory.mem[i][32 * 11 + 31:32 * 11]);
			$display("%h: %x", addr + 12 * 4, dataMemory.mem[i][32 * 12 + 31:32 * 12]);
			$display("%h: %x", addr + 13 * 4, dataMemory.mem[i][32 * 13 + 31:32 * 13]);
			$display("%h: %x", addr + 14 * 4, dataMemory.mem[i][32 * 14 + 31:32 * 14]);
			$display("%h: %x", addr + 15 * 4, dataMemory.mem[i][32 * 15 + 31:32 * 15]);
		end*/
		$finish;
		
	end

	pcControl pcControl(
		.clock(clock),
		.addempty(addRS.available),
		.lwempty(loadRS.available),
		.swempty(storeRS.available),
		.robempty(reorderBuffer.available),
		.bneempty(bneRS.available),
		
		.operatorType(instructionDecode.operatorType),
		.operatorSubType(instructionDecode.operatorSubType),
		.operatorFlag(instructionDecode.operatorFlag),
		.jump(branchPredictor.branchPCPredict),
		.jumppc(instructionDecode.data2),
		
		.pcChange(reorderBuffer.issueNewPCEnable),
		.changeData(reorderBuffer.issueNewPC)
	);

	instructionFetch instructionFetch(.pc(pcControl.pc));

	instructionDecode instructionDecode(
		.clock(clock),
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
		.ROBwriteType(reorderBuffer.regWriteType),
		.ROBwriteSubType(reorderBuffer.regWriteSubType),
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
		.reset(reorderBuffer.resetAll),
		
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
		
		.reset(reorderBuffer.resetAll),
		
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
		
		.hit(dataCache.hit),
		.data_in(dataCache.readData),
		
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
		.reset(reorderBuffer.resetAll),
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
		.operatorType(instructionDecode.operatorType),
		.robNum(reorderBuffer.space),
		.data1(regfile.data1),
		.data2(regfile.data2),
		.q1(regstatus.q1),
		.q2(regstatus.q2),
		.reset(reorderBuffer.resetAll),
		
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

	dataCache dataCache(

		.clk(clock),

		.readAddr(loadUnit.addr_out),
		.writeEnable(reorderBuffer.cacheWriteEnable), 
		.writeAddr(reorderBuffer.cacheWriteAddr),
		.writeData(reorderBuffer.cacheWriteData), 
		
		.memoryReadData(dataMemory.data_out),
		.memoryReadEnable(dataMemory.readEnable),
		.memoryWriteDone(dataMemory.writeDone)	
	);

	dataMemory dataMemory(

		.clock(clock),
		
		.readAddress(dataCache.memoryReadAddr),
		
		.writeAddress(dataCache.memoryWriteAddr),
		.writeRequest(dataCache.memoryWritePulse),
		.writeData(dataCache.memoryWriteData)
	);

	reorderBuffer reorderBuffer(
		.clk(clock),					

		.issue_opType(instructionDecode.operatorType),
		.issue_opSubType(instructionDecode.operatorSubType),
		.issue_opFlag(instructionDecode.operatorFlag),
		.issue_data2(instructionDecode.data2), 
		.issue_pc(pcControl.pc), 
		.issue_destReg(instructionDecode.destreg),	
		.issueValid(instructionDecode.ROBissueValid),
		
		.adderIndexIn(addRS.index), 
		.loadIndexIn(loadRS.index), 
		.storeIndexIn(storeRS.index), 
		.bneIndexIn(bneRS.index),
		
		.cacheWriteDone(dataCache.writeDone),
		
		.branchPrediction(branchPredictor.branchROBPredict),
		
		.storeEnable(storeRS.storeEnable), 
		.storeRobIndex(storeRS.robNum_out), 
		.storeDest(storeRS.data2_out), 
		.storeValue(storeRS.data1_out), 
		
		//CDB
		.CDBisCast1(CDBadd.iscast_out), 
		.CDBrobNum1(CDBadd.robNum_out), 
		.CDBdata1(CDBadd.data_out),
		
		.CDBisCast2(CDBlw.iscast_out), 
		.CDBrobNum2(CDBlw.robNum_out), 
		.CDBdata2(CDBlw.data_out),
		
		.statusResult(regstatus.ROBstatus),
		//Index Provider
		.cataclysm(instructionFetch.isdone),
		
		.bneWriteResult(bneRS.data_out), 
		.bneWriteEnable(bneRS.bneResultEnable), 
		.bneWriteIndex(bneRS.robNum_out)
	);

	branchPredictor branchPredictor(
		//Branch Write
		.branchWriteEnable(reorderBuffer.branchWriteEnable), 
		.branchWriteData(reorderBuffer.branchWriteData), 
		.branchWriteAddr(reorderBuffer.branchWriteAddr),
		//Branch Read for PC
		.branchPCReadAddr(pcControl.pc), 
		//Branch Read for ROB
		.branchROBReadAddr(reorderBuffer.branchAddr)
	);

endmodule
