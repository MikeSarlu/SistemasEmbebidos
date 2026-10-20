module Top_design (
      input  wire [15:0] A,
      input  wire [15:0] B,
      output wire [6:0]  D0,
      output wire [6:0]  D1,
      output wire [6:0]  D2,
      output wire [6:0]  D3,
      output wire        Cout
      );

      wire [15:0] S;
      wire [6:0] D0_int, D1_int, D2_int, D3_int;  

      Sumador_16bits U_SUMADOR (
            .A(A),
            .B(B),
            .S(S),
            .Cout(Cout)
      );

      Hex_7seg U_DISPLAY0 (.Suma(S[3:0]),   .Display(D0_int));
      Hex_7seg U_DISPLAY1 (.Suma(S[7:4]),   .Display(D1_int));
      Hex_7seg U_DISPLAY2 (.Suma(S[11:8]),  .Display(D2_int));
      Hex_7seg U_DISPLAY3 (.Suma(S[15:12]), .Display(D3_int));

      assign D0 = ~D0_int;
      assign D1 = ~D1_int;
      assign D2 = ~D2_int;
      assign D3 = ~D3_int;

endmodule