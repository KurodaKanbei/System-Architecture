/* ACM Class System (I) 2017 Fall Homework 1 
 *
 * PART II: Correct the following program
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put this file into `Simulation Sources'
 *   3. Run Behavioral Simulation
 *   4. You can see the results in `Tcl console'
 *
 */

module testfault;
	reg[15:0] a,b;
	wire[15:0] answer;
	fault f(a,b,answer);
	initial begin
		a = 10;
		b = 20;
		
		#1;
		if(answer != 20) begin
			$display("Expected 20, got %d", answer);
			//$fatal("Wrong Answer");
		end
		
		#1;
		
		a = 40;
		b = 30;
		
		#1;
		
		if(answer != 40) begin
			$display("Expected 40, got %d", answer);
			//$fatal("Wrong Answer");
		end
		
		$display("Congratulations! You have passed this test.");
		$finish;
	end
endmodule

module fault(a,b,answer);
	input wire[15:0] a,b;
	output reg[15:0] answer;
	always 
		@ (a or b) begin
			if (a > b) answer = a; else answer = b;
		end
endmodule
