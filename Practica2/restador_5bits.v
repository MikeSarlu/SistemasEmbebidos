module restador_5bits(
    input [4:0] A,
    input [4:0] B,
    input Bin,
    output [4:0] D,
    output Bout
);
    wire b1, b2, b3, b4;
 
    full_restador FR0(.a(A[0]),.b(B[0]),.bin(Bin),.d(D[0]),.bout(b1));
    full_restador FR1(.a(A[1]),.b(B[1]),.bin(b1),.d(D[1]),.bout(b2));
    full_restador FR2(.a(A[2]),.b(B[2]),.bin(b2),.d(D[2]),.bout(b3));
    full_restador FR3(.a(A[3]),.b(B[3]),.bin(b3),.d(D[3]),.bout(b4));
    full_restador FR4(.a(A[4]),.b(B[4]),.bin(b4),.d(D[4]),.bout(Bout));
endmodule