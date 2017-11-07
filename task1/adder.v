module onebitadder(A, B, Cin, Sum, Cout);
	input A, B, Cin;
	output Sum, Cout;
	reg Sum, Cout;
	reg T1, T2, T3;
	always 
		@ (A or B or Cin) begin
			Sum = A ^ B ^ Cin;
			T1 = A & B;
			T2 = A & Cin;
			T3 = B & Cin;
			Cout = T1 | T2 | T3;
		end
endmodule

module fourbitsadder(FA, FB, FCin, FSum, FCout);
	parameter N = 4;
	input [N : 1] FA, FB;
	output [N : 1] FSum;
	input FCin;
	output FCout;
	wire [N : 1] FTemp;
	onebitadder	
	FA1(.A(FA[1]), .B(FB[1]), .Cin(FCin), .Sum(FSum[1]), .Cout(FTemp[1])), 
	FA2(.A(FA[2]), .B(FB[2]), .Cin(FTemp[1]), .Sum(FSum[2]), .Cout(FTemp[2])),
	FA3(.A(FA[3]), .B(FB[3]), .Cin(FTemp[2]), .Sum(FSum[3]), .Cout(FTemp[3])),
	FA4(.A(FA[4]), .B(FB[4]), .Cin(FTemp[3]), .Sum(FSum[4]), .Cout(FCout));
endmodule

module adder(A, B, Sum);
	parameter N = 16;
	input [N : 1] A, B;
	output [N : 1] Sum;
	wire Cin[N : 0];
	assign Cin[0] = 0;
	fourbitsadder
	FA1(.FA(A[4 : 1]), .FB(B[4 : 1]), .FCin(Cin[0]), .FSum(Sum[4 : 1]), .FCout(Cin[4])),
	FA2(.FA(A[8 : 5]), .FB(B[8 : 5]), .FCin(Cin[4]), .FSum(Sum[8 : 5]), .FCout(Cin[8])),
	FA3(.FA(A[12 : 9]), .FB(B[12 : 9]), .FCin(Cin[8]), .FSum(Sum[12 : 9]), .FCout(Cin[12])),
	FA4(.FA(A[16 : 13]), .FB(B[16 : 13]), .FCin(Cin[12]), .FSum(Sum[16 : 13]), .FCout(Cin[16]));
endmodule
