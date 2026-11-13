function iguales = comparar_trazas(archivo_verilog, archivo_matlab)
%COMPARAR_TRAZAS Compara la traza del testbench con la de MATLAB.
%
%   comparar_trazas('ruta/traza_verilog.txt')
%   comparar_trazas('ruta/traza_verilog.txt', 'traza_matlab.txt')
%
%   Indica si ambas trazas son idénticas y, si no lo son, muestra la primera
%   fila donde difieren.

    if nargin < 2
        archivo_matlab = 'traza_matlab.txt';
    end

    V = load(archivo_verilog);
    M = load(archivo_matlab);
    columnas = {'escenario', 'segundo', 'fase', 't_restante', ...
                'cola N', 'cola S', 'cola E', 'cola O'};

    if ~isequal(size(V), size(M))
        fprintf('Tamaños distintos: Verilog %dx%d, MATLAB %dx%d\n', ...
                size(V, 1), size(V, 2), size(M, 1), size(M, 2));
        iguales = false;
        return
    end

    distintas = find(any(V ~= M, 2));
    iguales = isempty(distintas);

    if iguales
        fprintf('Las trazas coinciden en las %d filas.\n', size(V, 1));
        return
    end

    i = distintas(1);
    fprintf('%d filas distintas. Primera diferencia en la fila %d:\n', ...
            numel(distintas), i);
    fprintf('%-12s %8s %8s\n', 'Columna', 'Verilog', 'MATLAB');
    for c = 1:numel(columnas)
        marca = '';
        if V(i, c) ~= M(i, c)
            marca = '  <--';
        end
        fprintf('%-12s %8d %8d%s\n', columnas{c}, V(i, c), M(i, c), marca);
    end
end
