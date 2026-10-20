// Sumador de 4 bits con propagación de acarreo (ripple-carry)
module Sumador_4bits (
	input wire [3:0] A,
	input wire [3:0] B,
	input wire Cin,
	output wire [3:0] S,
	output wire Cout
);

	wire C1;
	wire C2;
	wire C3;
	
	Full_Adder FA0 (.A(A[0]),.B(B[0]),.Cin(Cin),.S(S[0]),.Cout(C1));
	Full_Adder FA1 (.A(A[1]),.B(B[1]),.Cin(C1),.S(S[1]),.Cout(C2));
	Full_Adder FA2 (.A(A[2]),.B(B[2]),.Cin(C2),.S(S[2]),.Cout(C3));
	Full_Adder FA3 (.A(A[3]),.B(B[3]),.Cin(C3),.S(S[3]),.Cout(Cout));
	
endmodule
