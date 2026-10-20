module signed_display_9bit (
    input  wire signed [8:0] value,
    output wire [6:0]        HEX0,
    output wire [6:0]        HEX1,
    output wire [6:0]        HEX2,
    output wire [6:0]        HEX3
);
 
    localparam [6:0] SEG_BLANK = 7'b1111111;
    localparam [6:0] SEG_MINUS = 7'b0111111;   // solo segmento g
 
    function [6:0] seg7;                       // {g,f,e,d,c,b,a}, activo en bajo
        input [3:0] d;
        case (d)
            4'd0:    seg7 = 7'b1000000;
            4'd1:    seg7 = 7'b1111001;
            4'd2:    seg7 = 7'b0100100;
            4'd3:    seg7 = 7'b0110000;
            4'd4:    seg7 = 7'b0011001;
            4'd5:    seg7 = 7'b0010010;
            4'd6:    seg7 = 7'b0000010;
            4'd7:    seg7 = 7'b1111000;
            4'd8:    seg7 = 7'b0000000;
            4'd9:    seg7 = 7'b0010000;
            default: seg7 = SEG_BLANK;
        endcase
    endfunction
 
    wire       negative  = value[8];
    // Magnitud: para -256 resulta 256, que cabe en 9 bits sin signo
    wire [8:0] magnitude = negative ? (~value + 9'd1) : value;
 
    wire [3:0] hundreds = magnitude / 9'd100;
    wire [3:0] tens     = (magnitude % 9'd100) / 9'd10;
    wire [3:0] units    = magnitude % 9'd10;
 
    assign HEX0 = seg7(units);
    assign HEX1 = (hundreds == 4'd0 && tens == 4'd0) ? SEG_BLANK : seg7(tens);
    assign HEX2 = (hundreds == 4'd0)                 ? SEG_BLANK : seg7(hundreds);
    assign HEX3 = negative ? SEG_MINUS : SEG_BLANK;
 
endmodule