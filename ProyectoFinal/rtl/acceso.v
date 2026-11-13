// Un acceso de la intersección: llegadas aleatorias, cola y descarga.
//
// En cada segundo simulado (tick):
//   1. El LFSR avanza 16 pasos. Si el valor resultante es menor que UMBRAL,
//      llega un vehículo.
//   2. Si el acceso tiene verde, sale un vehículo cada 2 s (flujo de
//      saturación de 1800 veh/h). El primer segundo de cada verde no hay
//      salida (tiempo perdido de arranque).
//   3. La cola se actualiza con saturación en 63.
//   4. Se actualiza el conteo de llegadas de los últimos 30 s.
//
// Cualquier cambio aquí debe reflejarse en matlab/simulador_trafico.m para que
// ambas trazas sigan siendo idénticas.

module acceso #(
    parameter [15:0] SEMILLA = 16'hACE1
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        tick,
    input  wire [15:0] umbral,      // probabilidad de llegada * 65536
    input  wire        verde,       // luz del acceso antes del tick
    output reg  [5:0]  cola,        // 0 a 63 vehículos
    output reg  [4:0]  llegadas_30, // llegadas en los últimos 30 s (0 a 30)
    output reg         llegada,     // pulsos de un ciclo después del tick
    output reg         salida,
    output reg         rechazo      // llegó un vehículo con la cola llena
);

    // LFSR de Galois de 16 bits, polinomio x^16 + x^14 + x^13 + x^11 + 1
    // (periodo máximo). Avanza 16 pasos por segundo simulado para que los
    // valores de segundos consecutivos no estén correlacionados.
    function [15:0] lfsr16;
        input [15:0] s;
        integer k;
        reg [15:0] x;
        begin
            x = s;
            for (k = 0; k < 16; k = k + 1)
                x = x[0] ? ((x >> 1) ^ 16'hB400) : (x >> 1);
            lfsr16 = x;
        end
    endfunction

    reg [15:0] lfsr;
    reg [29:0] historial;   // bit 0: segundo más reciente
    reg        alterna;     // descarga un vehículo cada 2 s durante el verde

    wire [15:0] lfsr_sig = lfsr16(lfsr);
    wire        arr      = (lfsr_sig < umbral);
    wire        dep      = verde && alterna && (cola != 6'd0);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr        <= SEMILLA;
            historial   <= 30'd0;
            alterna     <= 1'b0;
            cola        <= 6'd0;
            llegadas_30 <= 5'd0;
            llegada     <= 1'b0;
            salida      <= 1'b0;
            rechazo     <= 1'b0;
        end else begin
            llegada <= 1'b0;
            salida  <= 1'b0;
            rechazo <= 1'b0;

            if (tick) begin
                lfsr      <= lfsr_sig;
                historial <= {historial[28:0], arr};
                alterna   <= verde ? ~alterna : 1'b0;

                llegadas_30 <= llegadas_30 + arr - historial[29];

                case ({arr, dep})
                    2'b10:   cola <= (cola == 6'd63) ? cola : cola + 6'd1;
                    2'b01:   cola <= cola - 6'd1;
                    default: cola <= cola;
                endcase

                llegada <= arr;
                salida  <= dep;
                rechazo <= arr && !dep && (cola == 6'd63);
            end
        end
    end

endmodule
