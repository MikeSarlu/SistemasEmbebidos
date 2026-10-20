// Medio Sumador de 1 bit
module Half_Adder (
	input wire A, 
	input wire B,
	output S,
	output Cout
);

	assign S 	= A ^ B;
	assign Cout = A & B;
	
endmodule