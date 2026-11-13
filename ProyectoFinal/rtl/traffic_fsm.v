// Máquina de estados del semáforo (Tabla 2 del README).
//
// Las fases temporizadas avanzan con el tick de segundo simulado. Al terminar
// el rojo total, la FSM toma una muestra de las colas, solicita la duración del
// verde al controlador y espera su respuesta. Este intercambio dura unos
// cuantos ciclos de reloj, mucho menos que el periodo del tick, así que el
// verde siempre empieza antes del siguiente segundo simulado.

module traffic_fsm (
    input  wire       clk,
    input  wire       reset,
    input  wire       tick,

    input  wire [5:0] cola_n, cola_s, cola_e, cola_o,
    input  wire [4:0] lleg_n, lleg_s, lleg_e, lleg_o,

    // Interfaz con el controlador
    output reg        inicio,      // pulso: x1, x2 y x3 son válidos
    output reg  [5:0] x1,          // cola mayor de la fase que recibe el verde
    output reg  [5:0] x2,          // cola mayor de la fase que queda en rojo
    output reg  [4:0] x3,          // llegadas recientes mayores de la fase en verde
    input  wire       listo,       // pulso: t_verde es válido
    input  wire [5:0] t_verde,     // segundos

    output wire       verde_ns, amarillo_ns, rojo_ns,
    output wire       verde_eo, amarillo_eo, rojo_eo,
    output reg  [5:0] t_restante,
    output reg  [5:0] ultimo_verde
);

    localparam [3:0] S_ROJO_2     = 4'd0,   // rojo total antes del verde N-S
                     S_PIDE_NS    = 4'd1,
                     S_ESPERA_NS  = 4'd2,
                     S_NS_VERDE   = 4'd3,
                     S_NS_AMARIL  = 4'd4,
                     S_ROJO_1     = 4'd5,   // rojo total antes del verde E-O
                     S_PIDE_EO    = 4'd6,
                     S_ESPERA_EO  = 4'd7,
                     S_EO_VERDE   = 4'd8,
                     S_EO_AMARIL  = 4'd9;

    localparam [5:0] T_AMARILLO = 6'd3,
                     T_ROJO     = 6'd1,
                     T_MIN      = 6'd5,
                     T_MAX      = 6'd40;

    reg [3:0] estado;

    function [5:0] max6(input [5:0] a, input [5:0] b);
        max6 = (a > b) ? a : b;
    endfunction

    function [4:0] max5(input [4:0] a, input [4:0] b);
        max5 = (a > b) ? a : b;
    endfunction

    // Limita la respuesta del controlador al intervalo permitido
    function [5:0] limita(input [5:0] t);
        limita = (t < T_MIN) ? T_MIN : (t > T_MAX) ? T_MAX : t;
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado       <= S_ROJO_2;
            t_restante   <= T_ROJO;
            inicio       <= 1'b0;
            x1           <= 6'd0;
            x2           <= 6'd0;
            x3           <= 5'd0;
            ultimo_verde <= 6'd0;
        end else begin
            inicio <= 1'b0;

            case (estado)
                S_PIDE_NS: begin
                    x1     <= max6(cola_n, cola_s);
                    x2     <= max6(cola_e, cola_o);
                    x3     <= max5(lleg_n, lleg_s);
                    inicio <= 1'b1;
                    estado <= S_ESPERA_NS;
                end

                S_PIDE_EO: begin
                    x1     <= max6(cola_e, cola_o);
                    x2     <= max6(cola_n, cola_s);
                    x3     <= max5(lleg_e, lleg_o);
                    inicio <= 1'b1;
                    estado <= S_ESPERA_EO;
                end

                S_ESPERA_NS, S_ESPERA_EO: begin
                    if (listo) begin
                        t_restante   <= limita(t_verde);
                        ultimo_verde <= limita(t_verde);
                        estado       <= (estado == S_ESPERA_NS) ? S_NS_VERDE : S_EO_VERDE;
                    end
                end

                // Fases temporizadas
                default: begin
                    if (tick) begin
                        if (t_restante > 6'd1) begin
                            t_restante <= t_restante - 6'd1;
                        end else begin
                            case (estado)
                                S_NS_VERDE:  begin estado <= S_NS_AMARIL; t_restante <= T_AMARILLO; end
                                S_NS_AMARIL: begin estado <= S_ROJO_1;    t_restante <= T_ROJO;     end
                                S_ROJO_1:    begin estado <= S_PIDE_EO;   t_restante <= 6'd0;       end
                                S_EO_VERDE:  begin estado <= S_EO_AMARIL; t_restante <= T_AMARILLO; end
                                S_EO_AMARIL: begin estado <= S_ROJO_2;    t_restante <= T_ROJO;     end
                                default:     begin estado <= S_PIDE_NS;   t_restante <= 6'd0;       end
                            endcase
                        end
                    end
                end
            endcase
        end
    end

    assign verde_ns    = (estado == S_NS_VERDE);
    assign amarillo_ns = (estado == S_NS_AMARIL);
    assign rojo_ns     = !verde_ns && !amarillo_ns;
    assign verde_eo    = (estado == S_EO_VERDE);
    assign amarillo_eo = (estado == S_EO_AMARIL);
    assign rojo_eo     = !verde_eo && !amarillo_eo;

endmodule
