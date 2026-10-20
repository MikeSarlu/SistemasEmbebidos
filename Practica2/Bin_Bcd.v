module Bin_Bcd (
input wire [8:0] mult_out , // salida de tu multiplicador (0..511)
output wire [6:0] seg0 , // unidades
output wire [6:0] seg1 , // decenas
output wire [6:0] seg2 // centenas
) ;
wire [3:0] h , t , o ;

// Elige UNO de los dos convertidores :
 // bin9_to_bcd3_struct u0 (. bin ( mult_out ) , . hund ( h ) , . tens ( t ) , . ones ( o
) ) ;
bin9_to_bcd3_cmp_sub u0 (.bin(mult_out),.cent(c),.dec(d),.uni(u));

 // Reutilizas tu decodificador BCD - >7 seg tres veces
decoder_7seg s0 (.digito(u),.seg(seg0));
decoder_7seg s1 (.digito(d),.seg(seg1));
decoder_7seg s2 (.digito(c),.seg(seg2)); 

endmodule