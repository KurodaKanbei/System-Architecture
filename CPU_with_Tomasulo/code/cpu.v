`timescale 10ps / 100fs

module cpu();
	reg clock;
	wire exception;
	integer cycle;

	initial begin
		cycle = 0;
		clock = 0;
	end

	always #100 begin
		clock = ~clock;
		if (clock == 0) cycle = cycle + 1;
	end

	assign exception = reorderBuffer.Exception;

	integer i, j, addr;

	always @(posedge exception) begin
		for (i = 0; i <= 6; i++) begin
			//Let's print something here for debuging.		
		end
		$display("%d", cycle);
		$finish;
	end

	pcControl pcControl();

	instructionFetch instructionFetch();

	instructionDecode instructionDecode();

	regfile regfile();

	regstatus regstatus();

	addRS addRS();

	loadRS loadRS();

	loadUnit loadUnit();

	storeRS storeRS();

	bneRS bneRS();

	CDB CDBadd();

	CDB CDBlw();

	dataCache dataCache();

	dataMemory dataMemory();

	reorderBuffer reorderBuffer();

	branchPredictor branchPredictor();

endmodule

