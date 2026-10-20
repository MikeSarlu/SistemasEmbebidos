module multiplicador_lut(
    input  [4:0] magA,
    input  [4:0] magB,
    input signA,
    input  signB,
    output [9:0] mag,  
    output       sign   
);
    reg [9:0] rom [0:1023];  
    integer i, j;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                rom[i*32 + j] = i * j;
            end
        end
    end
 

    assign mag  = rom[{magA, magB}];
    assign sign = signA ^ signB;
endmodule