module adder_5bits(
    input [4:0] A,
    input [4:0] B,
    input Cin,
    output [4:0] S,
    output Cout
);
    wire c1, c2, c3, c4;
 
    full_adder FA0(.a(A[0]),.b(B[0]),.cin(Cin),.s(S[0]),.cout(c1));
    full_adder FA1(.a(A[1]),.b(B[1]),.cin(c1),.s(S[1]),.cout(c2));
    full_adder FA2(.a(A[2]),.b(B[2]),.cin(c2),.s(S[2]),.cout(c3));
    full_adder FA3(.a(A[3]),.b(B[3]),.cin(c3),.s(S[3]),.cout(c4));
    full_adder FA4(.a(A[4]),.b(B[4]),.cin(c4),.s(S[4]),.cout(Cout));
endmodule