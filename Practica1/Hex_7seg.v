module Hex_7seg (
	input wire [3:0] Suma,
	output wire [6:0] Display
	
	);
	wire b3 = Suma[3];
    wire b2 = Suma[2];
    wire b1 = Suma[1];
    wire b0 = Suma[0];   
	
	
	// A
    assign Display[6] = (b2 & b1) | (b3 & ~b0) | (b1 & ~b3) | (~b2 & ~b0) | (b2 & b0 & ~b3) | (b3 & ~b2 & ~b1);
	
	//B
	assign Display[5] = (~b3 & ~b2) | (~b2 & ~b0) | (b3 & b0 & ~b1) | (b1 & b0 & ~b3) | (~b3 & ~b1 & ~b0);
 	
	//C
	assign Display[4] = (b3 & ~b2) | (b2 & ~b3) | (b0 & ~b3) | (b0 & ~b1) | (~b3 & ~b1);
	
	//D
	assign Display[3] = (b3 & ~b1) | (b2 & b1 & ~b0) | (b2 & b0 & ~b1) | (b1 & b0 & ~b2) | (~b3 & ~b2 & ~b0);
	
	//E
	assign Display[2] = (b3 & b2) | (b3 & b1) | (b1 & ~b0) | (~b2 & ~b0);
	
	//F
	assign Display[1] = (b3 & b1) | (b3 & ~b2) | (b2 & ~b0) | (~b1 & ~b0) | (b2 & ~b3 & ~b1);
	
	//G
	assign Display[0] = (b3 & b0) | (b3 & ~b2) | (b1 & ~b2) | (b1 & ~b0) | (b2 & ~b3 & ~b1);

endmodule