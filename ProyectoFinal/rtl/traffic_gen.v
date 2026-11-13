// Generador de tráfico de la intersección: cuatro accesos con tasas de
// llegada definidas por el escenario seleccionado (Tabla 1 del README).

module traffic_gen (
    input  wire       clk,
    input  wire       reset,
    input  wire       tick,
    input  wire [2:0] escenario,
    input  wire       verde_ns,
    input  wire       verde_eo,
    output wire [5:0] cola_n, cola_s, cola_e, cola_o,
    output wire [4:0] lleg_n, lleg_s, lleg_e, lleg_o,
    output wire [3:0] llegada,   // {o, e, s, n}
    output wire [3:0] salida,
    output wire [3:0] rechazo
);

    // Umbrales = round(p * 65536)
    localparam [15:0] P03 = 16'd1966,  P05 = 16'd3277,  P08 = 16'd5243,
                      P10 = 16'd6554,  P12 = 16'd7864,  P15 = 16'd9830,
                      P18 = 16'd11796, P20 = 16'd13107, P22 = 16'd14418,
                      P25 = 16'd16384;

    // Segundos dentro de un ciclo de 30 min, para el escenario 111
    reg [10:0] seg_ciclo;

    always @(posedge clk or posedge reset) begin
        if (reset)
            seg_ciclo <= 11'd0;
        else if (tick)
            seg_ciclo <= (seg_ciclo == 11'd1799) ? 11'd0 : seg_ciclo + 11'd1;
    end

    // El escenario 111 alterna entre 011 y 100 cada 900 s
    wire [2:0] esc_efectivo = (escenario != 3'b111) ? escenario :
                              (seg_ciclo < 11'd900) ? 3'b011 : 3'b100;

    reg [15:0] u_n, u_s, u_e, u_o;

    always @(*) begin
        case (esc_efectivo)
            3'b000:  {u_n, u_s, u_e, u_o} = {P05, P05, P05, P05}; // baja uniforme
            3'b001:  {u_n, u_s, u_e, u_o} = {P12, P12, P12, P12}; // media uniforme
            3'b010:  {u_n, u_s, u_e, u_o} = {P18, P18, P18, P18}; // alta uniforme
            3'b011:  {u_n, u_s, u_e, u_o} = {P20, P20, P05, P05}; // principal N-S
            3'b100:  {u_n, u_s, u_e, u_o} = {P05, P05, P20, P20}; // principal E-O
            3'b101:  {u_n, u_s, u_e, u_o} = {P25, P03, P10, P10}; // un acceso cargado
            3'b110:  {u_n, u_s, u_e, u_o} = {P22, P15, P15, P08}; // hora pico asimétrica
            default: {u_n, u_s, u_e, u_o} = {P05, P05, P05, P05};
        endcase
    end

    acceso #(.SEMILLA(16'hACE1)) u_norte (
        .clk(clk), .reset(reset), .tick(tick), .umbral(u_n), .verde(verde_ns),
        .cola(cola_n), .llegadas_30(lleg_n),
        .llegada(llegada[0]), .salida(salida[0]), .rechazo(rechazo[0]));

    acceso #(.SEMILLA(16'h1D87)) u_sur (
        .clk(clk), .reset(reset), .tick(tick), .umbral(u_s), .verde(verde_ns),
        .cola(cola_s), .llegadas_30(lleg_s),
        .llegada(llegada[1]), .salida(salida[1]), .rechazo(rechazo[1]));

    acceso #(.SEMILLA(16'h5B3F)) u_este (
        .clk(clk), .reset(reset), .tick(tick), .umbral(u_e), .verde(verde_eo),
        .cola(cola_e), .llegadas_30(lleg_e),
        .llegada(llegada[2]), .salida(salida[2]), .rechazo(rechazo[2]));

    acceso #(.SEMILLA(16'hE2C4)) u_oeste (
        .clk(clk), .reset(reset), .tick(tick), .umbral(u_o), .verde(verde_eo),
        .cola(cola_o), .llegadas_30(lleg_o),
        .llegada(llegada[3]), .salida(salida[3]), .rechazo(rechazo[3]));

endmodule
