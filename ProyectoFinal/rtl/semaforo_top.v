// Módulo superior del semáforo inteligente para la DE10-Lite.
//
// Etapa 1: semáforo con controlador de tiempo fijo, generador de tráfico,
// displays y LEDs. El controlador difuso, las métricas y la VGA se agregan en
// etapas posteriores sin modificar la interfaz con la FSM.
//
// SW[1:0]  modo de control (por ahora todos usan tiempo fijo)
// SW[4:2]  escenario de tráfico
// SW[5]    velocidad de simulación: 0 = x1, 1 = x50
// SW[7:6]  contenido de los displays
// KEY[0]   reinicio general (activo en bajo)

module semaforo_top #(
    parameter integer CICLOS_X1  = 50_000_000,
    parameter integer CICLOS_X50 = 1_000_000
)(
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    // ------------------------------------------------------------------
    // Reinicio y sincronización de switches
    // ------------------------------------------------------------------
    reg [1:0] rst_sync;
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) rst_sync <= 2'b11;
        else         rst_sync <= {rst_sync[0], 1'b0};
    end
    wire reset = rst_sync[1];

    reg [9:0] sw_meta, sw_sync;
    always @(posedge CLOCK_50) begin
        sw_meta <= SW;
        sw_sync <= sw_meta;
    end

    wire [1:0] modo      = sw_sync[1:0];
    wire [2:0] escenario = sw_sync[4:2];
    wire       rapido    = sw_sync[5];
    wire [1:0] vista     = sw_sync[7:6];

    // ------------------------------------------------------------------
    // Núcleo del sistema
    // ------------------------------------------------------------------
    wire tick;
    wire [5:0] cola_n, cola_s, cola_e, cola_o;
    wire [4:0] lleg_n, lleg_s, lleg_e, lleg_o;
    wire [3:0] llegada, salida, rechazo;
    wire verde_ns, amarillo_ns, rojo_ns, verde_eo, amarillo_eo, rojo_eo;
    wire inicio, listo;
    wire [5:0] x1, x2, t_verde, t_restante, ultimo_verde;
    wire [4:0] x3;

    sim_tick #(.CICLOS_X1(CICLOS_X1), .CICLOS_X50(CICLOS_X50)) u_tick (
        .clk(CLOCK_50), .reset(reset), .rapido(rapido), .tick(tick));

    traffic_gen u_trafico (
        .clk(CLOCK_50), .reset(reset), .tick(tick), .escenario(escenario),
        .verde_ns(verde_ns), .verde_eo(verde_eo),
        .cola_n(cola_n), .cola_s(cola_s), .cola_e(cola_e), .cola_o(cola_o),
        .lleg_n(lleg_n), .lleg_s(lleg_s), .lleg_e(lleg_e), .lleg_o(lleg_o),
        .llegada(llegada), .salida(salida), .rechazo(rechazo));

    traffic_fsm u_fsm (
        .clk(CLOCK_50), .reset(reset), .tick(tick),
        .cola_n(cola_n), .cola_s(cola_s), .cola_e(cola_e), .cola_o(cola_o),
        .lleg_n(lleg_n), .lleg_s(lleg_s), .lleg_e(lleg_e), .lleg_o(lleg_o),
        .inicio(inicio), .x1(x1), .x2(x2), .x3(x3),
        .listo(listo), .t_verde(t_verde),
        .verde_ns(verde_ns), .amarillo_ns(amarillo_ns), .rojo_ns(rojo_ns),
        .verde_eo(verde_eo), .amarillo_eo(amarillo_eo), .rojo_eo(rojo_eo),
        .t_restante(t_restante), .ultimo_verde(ultimo_verde));

    controlador_fijo #(.T_FIJO(6'd20)) u_ctrl (
        .clk(CLOCK_50), .reset(reset), .inicio(inicio),
        .x1(x1), .x2(x2), .x3(x3),
        .listo(listo), .t_verde(t_verde));

    // ------------------------------------------------------------------
    // LEDs
    // ------------------------------------------------------------------
    reg pulso_seg;   // cambia en cada segundo simulado
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset)     pulso_seg <= 1'b0;
        else if (tick) pulso_seg <= ~pulso_seg;
    end

    assign LEDR[0]   = verde_ns;
    assign LEDR[1]   = amarillo_ns;
    assign LEDR[2]   = rojo_ns;
    assign LEDR[3]   = verde_eo;
    assign LEDR[4]   = amarillo_eo;
    assign LEDR[5]   = rojo_eo;
    assign LEDR[6]   = 1'b0;
    assign LEDR[7]   = pulso_seg;
    assign LEDR[9:8] = modo;

    // ------------------------------------------------------------------
    // Displays de 7 segmentos
    // ------------------------------------------------------------------
    // Cada par de displays muestra un número de 0 a 99. El código 4'hF se usa
    // para un guion (métricas que aún no están implementadas).
    localparam [3:0] GUION = 4'hF;

    reg [3:0] d0, d1, d2, d3, d4, d5;   // dígitos de HEX0 a HEX5

    function [7:0] dos_digitos(input [6:0] v);   // {decenas, unidades}
        reg [6:0] dec, uni;
        begin
            dec = v / 7'd10;
            uni = v % 7'd10;
            dos_digitos = {dec[3:0], uni[3:0]};
        end
    endfunction

    always @(*) begin
        case (vista)
            2'b00: begin   // tiempo restante, colas norte y sur
                {d1, d0} = dos_digitos({1'b0, t_restante});
                {d3, d2} = dos_digitos({1'b0, cola_n});
                {d5, d4} = dos_digitos({1'b0, cola_s});
            end
            2'b01: begin   // tiempo restante, colas este y oeste
                {d1, d0} = dos_digitos({1'b0, t_restante});
                {d3, d2} = dos_digitos({1'b0, cola_e});
                {d5, d4} = dos_digitos({1'b0, cola_o});
            end
            2'b10: begin   // métricas (etapa 4)
                {d1, d0} = {GUION, GUION};
                {d3, d2} = {GUION, GUION};
                {d5, d4} = {GUION, GUION};
            end
            default: begin // último verde, cola máxima (etapa 4), escenario y modo
                {d1, d0} = dos_digitos({1'b0, ultimo_verde});
                {d3, d2} = {GUION, GUION};
                d5 = {1'b0, escenario};
                d4 = {2'b00, modo};
            end
        endcase
    end

    wire [6:0] s0, s1, s2, s3, s4, s5;
    decoder_7seg u_d0 (.digito(d0), .seg(s0));
    decoder_7seg u_d1 (.digito(d1), .seg(s1));
    decoder_7seg u_d2 (.digito(d2), .seg(s2));
    decoder_7seg u_d3 (.digito(d3), .seg(s3));
    decoder_7seg u_d4 (.digito(d4), .seg(s4));
    decoder_7seg u_d5 (.digito(d5), .seg(s5));

    // decoder_7seg apaga el display para códigos mayores que 9; aquí se
    // sustituye el código GUION por el segmento g encendido.
    localparam [6:0] SEG_GUION = 7'b0111111;

    assign HEX0 = (d0 == GUION) ? SEG_GUION : s0;
    assign HEX1 = (d1 == GUION) ? SEG_GUION : s1;
    assign HEX2 = (d2 == GUION) ? SEG_GUION : s2;
    assign HEX3 = (d3 == GUION) ? SEG_GUION : s3;
    assign HEX4 = (d4 == GUION) ? SEG_GUION : s4;
    assign HEX5 = (d5 == GUION) ? SEG_GUION : s5;

endmodule
