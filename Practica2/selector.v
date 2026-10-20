module selector(
    input [9:0] sum_mag,
    input sum_sign,
    input [9:0] sub_mag,
    input sub_sign,
    input [9:0] mult_mag,
    input mult_sign,
    input [1:0] sel,
    output reg [9:0] mag,
    output reg sign
);
    always @(*) begin
        case (sel)
            2'b00: begin 
			mag = sum_mag; sign = sum_sign; // hace suma
			end  
			
		
            2'b01: begin 
			mag = sub_mag; sign = sub_sign;  // hace resta
			end   
			
            2'b10: begin 
			mag = mult_mag; sign = mult_sign; // hace multiplicacion
			end 
			
            default: begin mag = 10'b0; sign = 1'b0; 
			end
        endcase
    end
endmodule