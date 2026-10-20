module Full_Adder (
	input wire A,
	input wire B, 
	input wire Cin, 
	output wire S,
	output wire Cout
);

	// S = A xor B xor Cin 
	assign S = A ^ B ^ Cin;

	// Cout = AB + A*Cin + B*Cin
	assign Cout = (A & B) | (A & Cin) | (B & Cin);

endmodule
