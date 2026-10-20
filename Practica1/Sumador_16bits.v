// Sumador de 16 bits con propagación de acarreo (ripple-carry)
module Sumador_16bits (
    input  wire [15:0] A,
    input  wire [15:0] B,
    output wire [15:0] S,
    output wire        Cout
);

    wire [16:1] C;

    // Bit 0: Half Adder
    Half_Adder ha_inst (.A(A[0]),.B(B[0]),.S(S[0]),.Cout(C[1]));


    genvar i;
    generate
	for (i = 1; i < 16; i = i + 1) begin : 
		gen_fa Full_Adder fa_inst (.A(A[i]),.B(B[i]),.Cin(C[i]),.S(S[i]),.Cout(C[i+1]));
        end
    endgenerate

//acarreo final
    assign Cout = C[16];

endmodule

