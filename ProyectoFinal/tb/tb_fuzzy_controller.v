// Testbench del controlador difuso (etapa 2).
//
// Lee tb/vectores_fuzzy.txt, generado por matlab/vectores_prueba.m. Cada línea:
//
//   conjunto  x1  x2  x3  t_q  t_v  evalfis_ms
//
// Para cada vector comprueba que:
//   1. t_q y t_verde coinciden exactamente con matlab/fuzzy_punto_fijo.m.
//   2. |t_q / 256 - evalfis| < 0.5 s (criterio de la sección 7 del README).
// Al final reporta el error máximo respecto a evalfis y la latencia máxima.
//
// Los archivos se abren relativos a la carpeta de simulación; por omisión se
// supone que es ProyectoFinal/. Si no, cambiar los parámetros.

`timescale 1ns/1ps

module tb_fuzzy_controller;

    parameter ARCHIVO_ROM      = "rom/parametros.hex";
    parameter ARCHIVO_VECTORES = "tb/vectores_fuzzy.txt";

    reg        clk = 1'b0;
    reg        reset = 1'b1;
    reg  [1:0] conjunto = 2'd0;
    reg        inicio = 1'b0;
    reg  [5:0] x1 = 6'd0, x2 = 6'd0;
    reg  [4:0] x3 = 5'd0;
    wire       listo;
    wire [5:0] t_verde;
    wire [15:0] t_q;

    fuzzy_controller #(.ARCHIVO_ROM(ARCHIVO_ROM)) dut (
        .clk(clk), .reset(reset), .conjunto(conjunto), .inicio(inicio),
        .x1(x1), .x2(x2), .x3(x3),
        .listo(listo), .t_verde(t_verde), .t_q(t_q));

    always #10 clk = ~clk;   // 50 MHz

    integer f, leidos, n, errores, ciclos, ciclos_max;
    integer c_conj, c_x1, c_x2, c_x3, c_tq, c_tv, c_ms;
    real    err, err_max;

    initial begin
        errores    = 0;
        n          = 0;
        ciclos_max = 0;
        err_max    = 0.0;

        f = $fopen(ARCHIVO_VECTORES, "r");
        if (f == 0) begin
            $display("ERROR: no se pudo abrir %s", ARCHIVO_VECTORES);
            $finish;
        end

        repeat (3) @(posedge clk);
        reset = 1'b0;
        @(posedge clk);

        leidos = $fscanf(f, "%d %d %d %d %d %d %d\n",
                         c_conj, c_x1, c_x2, c_x3, c_tq, c_tv, c_ms);
        while (leidos == 7) begin
            // Entradas y pulso de inicio, como los entrega traffic_fsm.v
            @(negedge clk);
            conjunto = c_conj;
            x1 = c_x1;
            x2 = c_x2;
            x3 = c_x3;
            inicio = 1'b1;
            @(negedge clk);
            inicio = 1'b0;

            ciclos = 1;
            while (!listo) begin
                @(negedge clk);
                ciclos = ciclos + 1;
                if (ciclos > 200) begin
                    $display("ERROR: el controlador no respondio (vector %0d)", n);
                    $finish;
                end
            end
            if (ciclos > ciclos_max)
                ciclos_max = ciclos;

            if (t_q !== c_tq || t_verde !== c_tv) begin
                if (errores < 20)
                    $display("ERROR vector %0d: conj=%0d x=(%0d,%0d,%0d) t_q=%0d esperado %0d, t_verde=%0d esperado %0d",
                             n, c_conj, c_x1, c_x2, c_x3, t_q, c_tq, t_verde, c_tv);
                errores = errores + 1;
            end

            err = t_q / 256.0 - c_ms / 1000.0;
            if (err < 0.0)
                err = -err;
            if (err > err_max)
                err_max = err;
            if (err >= 0.5) begin
                $display("ERROR vector %0d: error de %f s respecto a evalfis", n, err);
                errores = errores + 1;
            end

            n = n + 1;
            leidos = $fscanf(f, "%d %d %d %d %d %d %d\n",
                             c_conj, c_x1, c_x2, c_x3, c_tq, c_tv, c_ms);
        end
        $fclose(f);

        $display("Vectores probados: %0d", n);
        $display("Error maximo respecto a evalfis: %f s (incluye el redondeo a ms del archivo)", err_max);
        $display("Latencia maxima: %0d ciclos", ciclos_max);
        if (n == 0)
            $display("ERROR: no se leyo ningun vector");
        else if (errores == 0)
            $display("Simulacion terminada sin errores");
        else
            $display("Simulacion terminada con %0d errores", errores);
        $finish;
    end

endmodule
