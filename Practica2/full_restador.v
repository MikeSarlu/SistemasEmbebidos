module full_restador(
    input a, b, bin,
    output d, bout
);					   

    assign d = a ^ b ^ bin;
    assign bout = (~a & b) | (~a & bin) | (b & bin);	  
	
endmodule