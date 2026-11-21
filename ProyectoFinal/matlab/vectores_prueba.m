function vectores_prueba(rom, conjuntos, n_vectores)
%VECTORES_PRUEBA Vectores de prueba de rtl/fuzzy_controller.v.
%
%   vectores_prueba(rom, conjuntos)
%   vectores_prueba(rom, conjuntos, n_vectores)
%
%   rom y conjuntos son las salidas de exportar_parametros. Para cada uno de
%   los cuatro conjuntos se generan casos límite y n_vectores entradas
%   aleatorias (1000 por omisión). Escribe ../tb/vectores_fuzzy.txt, que lee
%   tb/tb_fuzzy_controller.v. Cada línea tiene:
%
%     conjunto  x1  x2  x3  t_q  t_v  evalfis_ms
%
%   t_q y t_v son la salida exacta esperada del Verilog (fuzzy_punto_fijo.m) y
%   evalfis_ms es la salida de evalfis en milisegundos, redondeada.
%
%   También imprime el error de cuantización respecto a evalfis, que debe ser
%   menor a 0.5 s (sección 7 del README).

    if nargin < 3
        n_vectores = 1000;
    end
    rng(2026);   % misma secuencia de vectores en cada ejecución

    % Casos límite: extremos, vértices y puntos intermedios de cada entrada
    v12 = [0 1 7 14 15 16 29 30 31 45 62 63];
    v3  = [0 1 4 5 6 9 10 11 20 30];
    [a, b, c] = ndgrid(v12, v12, v3);
    limites = [a(:) b(:) c(:)];

    aleatorios = [randi([0 63], n_vectores, 1), randi([0 63], n_vectores, 1), ...
                  randi([0 30], n_vectores, 1)];
    X = [limites; aleatorios];
    n = size(X, 1);

    datos = zeros(4*n, 7);
    nombres = {'tiempo fijo', 'manual', 'ANFIS', 'fminsearch'};
    fprintf('%-12s %10s %16s %14s\n', 'Conjunto', 'Vectores', ...
            'Error max (s)', 'Redondeo dif.');

    for s = 0:3
        y = evalfis(conjuntos{s+1}, X);
        tq = zeros(n, 1);
        tv = zeros(n, 1);
        for i = 1:n
            [tq(i), tv(i)] = fuzzy_punto_fijo(rom, s, X(i,1), X(i,2), X(i,3));
        end
        error_max = max(abs(tq / 256 - y));
        difieren  = sum(tv ~= min(max(round(y), 0), 63));
        fprintf('%-12s %10d %16.4f %14d\n', nombres{s+1}, n, error_max, difieren);
        if error_max >= 0.5
            warning('Conjunto %d: el error de cuantización supera 0.5 s.', s);
        end
        datos(s*n + (1:n), :) = [repmat(s, n, 1) X tq tv round(1000 * y)];
    end

    archivo = fullfile('..', 'tb', 'vectores_fuzzy.txt');
    writematrix(datos, archivo, 'Delimiter', ' ');
    fprintf('\n%d vectores escritos en %s\n', size(datos, 1), archivo);
    fprintf('"Redondeo dif." cuenta los casos en que el segundo entero del\n');
    fprintf('hardware difiere de round(evalfis) por la cuantización.\n');
end
