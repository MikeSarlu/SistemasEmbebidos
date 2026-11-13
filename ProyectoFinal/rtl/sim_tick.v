// Genera un pulso de un ciclo por cada segundo simulado.
// Adaptado de tick_generator.v (Práctica 3) con solo dos velocidades.

module sim_tick #(
    parameter integer CICLOS_X1  = 50_000_000,  // 1 s simulado = 1 s real
    parameter integer CICLOS_X50 = 1_000_000    // 1 s simulado = 20 ms
)(
    input  wire clk,
    input  wire reset,
    input  wire rapido,
    output reg  tick
);

    reg  [25:0] cuenta;
    wire [25:0] limite = rapido ? (CICLOS_X50 - 1) : (CICLOS_X1 - 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cuenta <= 26'd0;
            tick   <= 1'b0;
        end else if (cuenta >= limite) begin   // >= por si se cambia de velocidad a medio conteo
            cuenta <= 26'd0;
            tick   <= 1'b1;
        end else begin
            cuenta <= cuenta + 26'd1;
            tick   <= 1'b0;
        end
    end

endmodule
