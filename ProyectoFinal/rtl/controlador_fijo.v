// Controlador de tiempo fijo. Responde siempre con la misma duración de verde.
//
// Tiene la misma interfaz que tendrá fuzzy_controller.v, de modo que la FSM no
// cambia cuando se agregue el controlador difuso. También sirve como línea base
// para la comparación de resultados.

module controlador_fijo #(
    parameter [5:0] T_FIJO = 6'd20
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       inicio,
    input  wire [5:0] x1,
    input  wire [5:0] x2,
    input  wire [4:0] x3,
    output reg        listo,
    output reg  [5:0] t_verde
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            listo   <= 1'b0;
            t_verde <= T_FIJO;
        end else begin
            listo   <= inicio;
            t_verde <= T_FIJO;
        end
    end

endmodule
