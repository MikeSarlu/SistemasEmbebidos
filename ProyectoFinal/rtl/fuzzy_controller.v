// Controlador difuso Sugeno de orden cero (sección 5.3 del README).
//
// Tiene la misma interfaz que controlador_fijo.v más la selección del conjunto
// de parámetros. Al recibir el pulso "inicio":
//
//   1. Lee de la ROM los 45 parámetros de las 9 funciones triangulares y
//      calcula los 9 grados de pertenencia, uno cada 5 ciclos:
//        mu = (x - a) * 1/(b-a)   si a < x <= b
//        mu = (c - x) * 1/(c-b)   si b < x <  c
//        mu = 0                   en otro caso
//   2. Lee los 27 consecuentes y evalúa una regla por ciclo en un pipeline de
//      tres etapas: w12 = mu1*mu2, w = w12*mu3, y acumula w y w*z.
//   3. Divide ambos acumuladores con un divisor de restauración de 16 ciclos.
//
// El cálculo completo toma unos 95 ciclos (menos de 2 us a 50 MHz).
//
// Formatos (ver matlab/exportar_parametros.m):
//   x               entero, se trata como Q8.8 (x * 256)
//   a, b, c         Q8.8 con signo
//   1/(b-a), 1/(c-b) Q0.16 sin signo
//   z               Q8.8 sin signo
//   mu, w           Q0.16 (65535 representa 1)
//   acc_w           Q5.16       acc_wz  Q8.16
//   t_q             Q8.8 (salida antes de redondear)
//
// matlab/fuzzy_punto_fijo.m reproduce estas operaciones bit a bit; cualquier
// cambio aquí debe reflejarse allá.

module fuzzy_controller #(
    parameter ARCHIVO_ROM = "../rom/parametros.hex"
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  conjunto,    // 0 fijo, 1 manual, 2 ANFIS, 3 fminsearch
    input  wire        inicio,      // pulso: x1, x2 y x3 son válidos
    input  wire [5:0]  x1,          // cola mayor de la fase que recibe el verde
    input  wire [5:0]  x2,          // cola mayor de la fase que queda en rojo
    input  wire [4:0]  x3,          // llegadas recientes de la fase en verde
    output reg         listo,       // pulso: t_verde y t_q son válidos
    output reg  [5:0]  t_verde,     // segundos, redondeado (0 a 63)
    output reg  [15:0] t_q          // segundos en Q8.8
);

    localparam [6:0]  N_PALABRAS = 7'd72;       // 45 de funciones + 27 consecuentes
    localparam [6:0]  INICIO_Z   = 7'd45;
    localparam [15:0] T_RESPALDO = 16'd5120;    // 20 s si ninguna regla se activa

    localparam [2:0] S_REPOSO  = 3'd0,
                     S_LEE     = 3'd1,
                     S_VACIA   = 3'd2,
                     S_DIV_INI = 3'd3,
                     S_DIVIDE  = 3'd4,
                     S_FIN     = 3'd5;

    reg [2:0] estado;

    // Entradas capturadas
    reg [1:0] conj;
    reg [5:0] xr1, xr2;
    reg [4:0] xr3;

    // ------------------------------------------------------------------
    // ROM
    // ------------------------------------------------------------------
    reg  [6:0]  dir;          // dirección dentro del conjunto
    wire [15:0] rom_q;

    rom_parametros #(.ARCHIVO(ARCHIVO_ROM)) u_rom (
        .clk(clk), .dir({conj, dir}), .dato(rom_q));

    // El dato de la dirección emitida en un ciclo llega en el siguiente
    reg       rv;             // rom_q es válido
    reg [6:0] rdir;           // dirección a la que corresponde rom_q

    // ------------------------------------------------------------------
    // Grados de pertenencia
    // ------------------------------------------------------------------
    reg [15:0] mu [0:8];      // mu[3*j + m]: función m de la entrada j
    reg [2:0]  k5;            // palabra dentro de la función (0 a 4)
    reg [3:0]  g;             // función que se está leyendo (0 a 8)
    reg signed [15:0] ra, rb, rc;
    reg [15:0] ril;

    wire [5:0] xsel = (g < 4'd3) ? xr1 :
                      (g < 4'd6) ? xr2 : {1'b0, xr3};

    wire signed [16:0] xs = {3'b000, xsel, 8'h00};
    wire signed [16:0] as = ra;
    wire signed [16:0] bs = rb;
    wire signed [16:0] cs = rc;

    wire               fuera    = (xs <= as) || (xs >= cs);
    wire               izq      = (xs <= bs);
    wire signed [16:0] dif      = izq ? (xs - as) : (cs - xs);
    wire [15:0]        inv      = izq ? ril : rom_q;   // rom_q trae 1/(c-b)
    wire [31:0]        prod_mu  = dif[15:0] * inv;
    wire [23:0]        mu_raw   = prod_mu[31:8];
    wire [15:0]        mu_nuevo = fuera            ? 16'd0   :
                                  (|mu_raw[23:16]) ? 16'hFFFF : mu_raw[15:0];

    // ------------------------------------------------------------------
    // Reglas: pipeline de tres etapas
    // ------------------------------------------------------------------
    reg [1:0]  m1, m2, m3;    // funciones de la regla que llega de la ROM
    reg [1:0]  m3_r;
    reg        v1, v2;
    reg [15:0] w12, w;
    reg [15:0] z1, z2;
    reg [4:0]  n_acc;         // reglas acumuladas
    reg [31:0] acc_w, acc_wz;

    wire [31:0] prod_w12 = mu[m1] * mu[4'd3 + m2];
    wire [31:0] prod_w   = w12 * mu[4'd6 + m3_r];
    wire [31:0] prod_wz  = w * z2;

    // ------------------------------------------------------------------
    // Divisor de restauración: quo = floor(acc_wz * 256 / acc_w)
    // ------------------------------------------------------------------
    // Como t_q < 2^16, la parte alta del dividendo (acc_wz >> 8) es menor que
    // acc_w y bastan 16 iteraciones, una por bit del cociente.
    reg  [23:0] rem;
    reg  [15:0] bits;         // bits restantes del dividendo: {acc_wz[7:0], 8'h00}
    reg  [15:0] quo;
    reg  [4:0]  n_div;
    wire [24:0] rem_s = {rem, bits[15]};
    wire        resta = (rem_s >= acc_w);

    // Redondeo al segundo con saturación en 63
    wire [16:0] t_red = {1'b0, quo} + 17'd128;
    wire [8:0]  t_ent = t_red[16:8];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado  <= S_REPOSO;
            listo   <= 1'b0;
            t_verde <= 6'd20;
            t_q     <= T_RESPALDO;
            conj    <= 2'd0;
            xr1     <= 6'd0;
            xr2     <= 6'd0;
            xr3     <= 5'd0;
            dir     <= 7'd0;
            rv      <= 1'b0;
            rdir    <= 7'd0;
            k5      <= 3'd0;
            g       <= 4'd0;
            ra      <= 16'sd0;
            rb      <= 16'sd0;
            rc      <= 16'sd0;
            ril     <= 16'd0;
            m1      <= 2'd0;
            m2      <= 2'd0;
            m3      <= 2'd0;
            m3_r    <= 2'd0;
            v1      <= 1'b0;
            v2      <= 1'b0;
            w12     <= 16'd0;
            w       <= 16'd0;
            z1      <= 16'd0;
            z2      <= 16'd0;
            n_acc   <= 5'd0;
            acc_w   <= 32'd0;
            acc_wz  <= 32'd0;
            rem     <= 24'd0;
            bits    <= 16'd0;
            quo     <= 16'd0;
            n_div   <= 5'd0;
        end else begin
            listo <= 1'b0;

            // ---------------- Lectura de la ROM ----------------
            rv   <= (estado == S_LEE);
            rdir <= dir;

            // ---------------- Pertenencias ----------------
            if (rv && rdir < INICIO_Z) begin
                case (k5)
                    3'd0: ra  <= rom_q;
                    3'd1: rb  <= rom_q;
                    3'd2: rc  <= rom_q;
                    3'd3: ril <= rom_q;
                    default: begin
                        mu[g] <= mu_nuevo;
                        g     <= g + 4'd1;
                    end
                endcase
                k5 <= (k5 == 3'd4) ? 3'd0 : k5 + 3'd1;
            end

            // ---------------- Reglas, etapa 1 ----------------
            v1 <= rv && (rdir >= INICIO_Z);
            if (rv && rdir >= INICIO_Z) begin
                w12  <= prod_w12[31:16];
                z1   <= rom_q;
                m3_r <= m3;
                // Siguiente regla: m3 cambia más rápido
                if (m3 == 2'd2) begin
                    m3 <= 2'd0;
                    if (m2 == 2'd2) begin
                        m2 <= 2'd0;
                        m1 <= m1 + 2'd1;
                    end else begin
                        m2 <= m2 + 2'd1;
                    end
                end else begin
                    m3 <= m3 + 2'd1;
                end
            end

            // ---------------- Reglas, etapa 2 ----------------
            v2 <= v1;
            if (v1) begin
                w  <= prod_w[31:16];
                z2 <= z1;
            end

            // ---------------- Reglas, etapa 3 ----------------
            if (v2) begin
                acc_w  <= acc_w  + {16'd0, w};
                acc_wz <= acc_wz + {8'd0, prod_wz[31:8]};
                n_acc  <= n_acc + 5'd1;
            end

            // ---------------- Control ----------------
            case (estado)
                S_REPOSO: begin
                    if (inicio) begin
                        conj   <= conjunto;
                        xr1    <= x1;
                        xr2    <= x2;
                        xr3    <= x3;
                        dir    <= 7'd0;
                        k5     <= 3'd0;
                        g      <= 4'd0;
                        m1     <= 2'd0;
                        m2     <= 2'd0;
                        m3     <= 2'd0;
                        n_acc  <= 5'd0;
                        acc_w  <= 32'd0;
                        acc_wz <= 32'd0;
                        estado <= S_LEE;
                    end
                end

                S_LEE: begin
                    if (dir == N_PALABRAS - 7'd1)
                        estado <= S_VACIA;
                    else
                        dir <= dir + 7'd1;
                end

                S_VACIA: begin   // espera a que la última regla se acumule
                    if (v2 && n_acc == 5'd26)
                        estado <= S_DIV_INI;
                end

                S_DIV_INI: begin
                    if (acc_w == 32'd0) begin
                        quo    <= T_RESPALDO;
                        estado <= S_FIN;
                    end else begin
                        rem    <= acc_wz[31:8];
                        bits   <= {acc_wz[7:0], 8'h00};
                        quo    <= 16'd0;
                        n_div  <= 5'd16;
                        estado <= S_DIVIDE;
                    end
                end

                S_DIVIDE: begin
                    rem   <= resta ? (rem_s - acc_w[24:0]) : rem_s[23:0];
                    quo   <= {quo[14:0], resta};
                    bits  <= {bits[14:0], 1'b0};
                    n_div <= n_div - 5'd1;
                    if (n_div == 5'd1)
                        estado <= S_FIN;
                end

                default: begin   // S_FIN
                    t_q     <= quo;
                    t_verde <= (t_ent > 9'd63) ? 6'd63 : t_ent[5:0];
                    listo   <= 1'b1;
                    estado  <= S_REPOSO;
                end
            endcase
        end
    end

endmodule
