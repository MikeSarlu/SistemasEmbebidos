// Testbench del sistema completo (etapa 1: controlador de tiempo fijo).
//
// Corre los 8 escenarios durante una hora simulada cada uno y escribe, en cada
// segundo simulado, el estado del semáforo y las cuatro colas en
// traza_verilog.txt. Ese archivo se compara con la traza que genera
// matlab/generar_traza_referencia.m usando matlab/comparar_trazas.m.
//
// Formato de cada línea:  escenario  segundo  fase  t_restante  N  S  E  O
// fase: 0 rojo total, 1 verde N-S, 2 amarillo N-S, 3 verde E-O, 4 amarillo E-O
//
// Además verifica en cada ciclo que nunca haya dos fases con paso al mismo
// tiempo y que ningún tick llegue mientras la FSM espera al controlador.

`timescale 1ns/1ps

module tb_semaforo;

    localparam integer N_SEG = 3600;   // segundos simulados por escenario

    reg        CLOCK_50 = 1'b0;
    reg  [1:0] KEY      = 2'b11;
    reg  [9:0] SW       = 10'd0;
    wire [9:0] LEDR;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // Ticks cada 200 ciclos para que la simulación sea corta
    semaforo_top #(.CICLOS_X1(400), .CICLOS_X50(200)) dut (
        .CLOCK_50(CLOCK_50), .KEY(KEY), .SW(SW), .LEDR(LEDR),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5));

    always #10 CLOCK_50 = ~CLOCK_50;   // 50 MHz

    integer f, esc, k, errores;
    reg     registrando = 1'b0;

    wire [2:0] fase = dut.verde_ns    ? 3'd1 :
                      dut.amarillo_ns ? 3'd2 :
                      dut.verde_eo    ? 3'd3 :
                      dut.amarillo_eo ? 3'd4 : 3'd0;

    // Registro de la traza: valores antes de aplicar cada tick
    always @(posedge CLOCK_50) begin
        if (registrando && dut.tick) begin
            $fdisplay(f, "%0d %0d %0d %0d %0d %0d %0d %0d", esc, k, fase,
                      dut.t_restante, dut.cola_n, dut.cola_s, dut.cola_e, dut.cola_o);
            k = k + 1;
        end
    end

    // Verificaciones
    always @(posedge CLOCK_50) begin
        if (!dut.reset) begin
            if ((dut.verde_ns || dut.amarillo_ns) && (dut.verde_eo || dut.amarillo_eo)) begin
                $display("ERROR t=%0t: ambas fases con paso", $time);
                errores = errores + 1;
            end
            if (dut.tick && (dut.u_fsm.estado == 4'd1 || dut.u_fsm.estado == 4'd2 ||
                             dut.u_fsm.estado == 4'd6 || dut.u_fsm.estado == 4'd7)) begin
                $display("ERROR t=%0t: tick mientras la FSM espera al controlador", $time);
                errores = errores + 1;
            end
        end
    end

    initial begin
        errores = 0;
        f = $fopen("traza_verilog.txt", "w");

        for (esc = 0; esc < 8; esc = esc + 1) begin
            // vista 00, velocidad x50, escenario esc, modo 00
            SW = {2'b00, 2'b00, 1'b1, esc[2:0], 2'b00};

            KEY[0] = 1'b0;
            repeat (5) @(posedge CLOCK_50);
            KEY[0] = 1'b1;

            k = 0;
            registrando = 1'b1;
            wait (k == N_SEG);
            registrando = 1'b0;

            $display("Escenario %0d: colas al final N=%0d S=%0d E=%0d O=%0d",
                     esc, dut.cola_n, dut.cola_s, dut.cola_e, dut.cola_o);
        end

        $fclose(f);

        if (errores == 0)
            $display("Simulacion terminada sin errores. Traza en traza_verilog.txt");
        else
            $display("Simulacion terminada con %0d errores", errores);
        $finish;
    end

endmodule
