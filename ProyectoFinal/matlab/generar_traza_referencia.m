%GENERAR_TRAZA_REFERENCIA Traza de referencia para validar el Verilog.
%   Corre los 8 escenarios con el controlador de tiempo fijo durante una hora
%   simulada y escribe traza_matlab.txt con el mismo formato que
%   tb/tb_semaforo.v. También imprime las métricas de cada escenario, que
%   sirven como línea base de la comparación.

N_SEG = 3600;
nombres = {'Baja uniforme', 'Media uniforme', 'Alta uniforme', ...
           'Principal N-S', 'Principal E-O', 'Un acceso cargado', ...
           'Hora pico asimetrica', 'Demanda cambiante'};

traza = zeros(0, 8);
fprintf('%-22s %10s %10s %10s %10s\n', 'Escenario', 'Llegadas', ...
        'Atendidos', 'Demora(s)', 'Cola max');

for esc = 0:7
    [t, r] = simulador_trafico(esc, N_SEG);
    traza = [traza; t]; %#ok<AGROW>
    fprintf('%-22s %10d %10d %10.1f %10d\n', nombres{esc+1}, r.llegadas, ...
            r.atendidos, r.demora_promedio, r.cola_max);
end

writematrix(traza, 'traza_matlab.txt', 'Delimiter', ' ');
fprintf('\nTraza escrita en traza_matlab.txt (%d filas)\n', size(traza, 1));
