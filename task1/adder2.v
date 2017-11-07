/* ACM Class System (I) 2017 Fall Homework 1 
 *
 * Part I: Write an adder in Verilog
 *
 * Implement your Carry Look Ahead Adder here
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put this file into `Sources'
 *   3. Put `test_adder.v' into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *
 */

module fastadder(a, b, cin, sum, cout);
	parameter N = 4;
	input [N : 1] a, b;
	output [N : 1] sum;
	input cin;
	output cout;
	wire [N : 1] c, g, p;
	assign g[1] = a[1] & b[1], g[2] = a[2] & b[2], g[3] = a[3] & b[3], g[4] = a[4] & b[4];
	assign p[1] = a[1] | b[1], p[2] = a[2] | b[2], p[3] = a[3] | b[3], p[4] = a[4] | b[4];
	assign c[1] = g[1] | (p[1] & cin), c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & cin),
	c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & cin),
	cout = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & cin);
	assign sum[N : 1] = a[N : 1] ^ b[N : 1] ^ {c[N - 1: 1], cin};
endmodule

module adder(A, B, Sum);
	parameter N = 16;
	input [N : 1] A, B;
	output [N : 1] Sum;
	wire [N : 0] Cin;
	assign Cin[0] = 0;
	fastadder
	FA1(.a(A[4 : 1]), .b(B[4 : 1]), .cin(Cin[0]), .sum(Sum[4 : 1]), .cout(Cin[4])),
	FA2(.a(A[8 : 5]), .b(B[8 : 5]), .cin(Cin[4]), .sum(Sum[8 : 5]), .cout(Cin[8])),
	FA3(.a(A[12 : 9]), .b(B[12 : 9]), .cin(Cin[8]), .sum(Sum[12 : 9]), .cout(Cin[12])),
	FA4(.a(A[16 : 13]), .b(B[16 : 13]), .cin(Cin[12]), .sum(Sum[16 : 13]), .cout(Cin[16]));
endmodule
