module magnitude(
    input [4:0] Din,     
    output sign,    
    output [4:0] mag   
);
    wire [4:0] inverted;
    wire [4:0] comp;
    wire  cout1;
 
    assign sign = Din[4];     
    assign inverted = ~Din;
 

    adder_5bits calc_mag (.A(inverted),.B(5'b00000),.Cin(1'b1),.S(comp),.Cout(cout1));
 
    assign mag = sign ? comp : Din;
endmodule