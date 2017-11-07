
/* ACM Class System (I) 2017 Fall Homework 1 
 *
 * Part I: Write an adder in Verilog
 *
 * This file is used to test your adder. 
 * Please DO NOT modify this file.
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put `adder.v' OR `adder2.v' into `Sources', DO NOT add both of them at the same time.
 *   3. Put this file into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *
 */

`include "adder.v"

module test_adder;
	wire [15:0] answer;
	reg[15:0]  a, b;
	adder adder(a, b, answer);
	integer i;
	initial begin
		for(i=1; i<=100; i=i+1) begin
			a[14:0] = $random;
			a[15] = 0;
			b[14:0] = $random;
			b[15] = 0;
			
			#1;
			$display("TESTCASE %d: %d + %d = %d", i, a, b, answer);

			if (answer !== a + b) begin
				//$fatal("Wrong Answer!");
				$finish;
			end
		end
		$display("Congratulations! You have passed all of the tests.");
		$finish;
	end
endmodule
