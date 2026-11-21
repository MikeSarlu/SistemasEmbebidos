function [rom, conjuntos] = exportar_parametros(fis_man, fis_anfis, fis_fmin)
%EXPORTAR_PARAMETROS Cuantiza los FIS y escribe la ROM del controlador.
%
%   [rom, conjuntos] = exportar_parametros(fis_man)
%   [rom, conjuntos] = exportar_parametros(fis_man, fis_anfis, fis_fmin)
%
%   Escribe ../rom/parametros.hex (para $readmemh en simulación y en Quartus)
%   y ../rom/parametros.mif. Se ejecuta con matlab/ como carpeta actual.
%
%   La ROM tiene cuatro conjuntos de 128 palabras, seleccionados con SW[1:0]:
%     0  tiempo fijo  (funciones del manual, todos los consecuentes en 20 s)
%     1  difuso manual
%     2  ANFIS        (si fis_anfis está vacío se usa el manual)
%     3  fminsearch   (si fis_fmin está vacío se usa el manual)
%
%   Organización de cada conjunto (direcciones relativas):
%     0-44   para la entrada j y la función m, en (3j + m) * 5:
%            a, b, c en Q8.8 con signo; 1/(b-a) y 1/(c-b) en Q0.16
%     45-71  consecuentes z en Q8.8; la regla (m1, m2, m3) va en
%            45 + 9 m1 + 3 m2 + m3 (índices desde 0)
%     72-127 reserva (ceros)
%
%   Antes de cuantizar, cada FIS se valida y se corrige:
%     - vértices ordenados (ANFIS puede desordenarlos)
%     - rangos de entrada iguales a los del hardware, para que evalfis no
%       recorte entradas que el Verilog sí procesa
%     - consecuentes limitados a [0 63] s, lo que cabe en t_verde
%     - la suma de pertenencias cuantizadas nunca es cero en el rango
%
%   conjuntos devuelve los cuatro FIS ya corregidos, que son los que se usan
%   como referencia con evalfis en vectores_prueba.m.

    if nargin < 2, fis_anfis = []; end
    if nargin < 3, fis_fmin  = []; end

    fis_man = corregir(fis_man, 'manual');

    fis_fijo = fis_man;
    fis_fijo.Name = 'semaforo_fijo';
    for k = 1:numel(fis_fijo.Outputs(1).MembershipFunctions)
        fis_fijo.Outputs(1).MembershipFunctions(k).Parameters = 20;
    end

    if isempty(fis_anfis)
        warning('exportar_parametros:sinAnfis', ...
                'No hay FIS de ANFIS; el conjunto 2 usa el manual.');
        fis_anfis = fis_man;
    else
        fis_anfis = corregir(fis_anfis, 'ANFIS');
    end

    if isempty(fis_fmin)
        warning('exportar_parametros:sinFmin', ...
                'No hay FIS de fminsearch; el conjunto 3 usa el manual.');
        fis_fmin = fis_man;
    else
        fis_fmin = corregir(fis_fmin, 'fminsearch');
    end

    conjuntos = {fis_fijo, fis_man, fis_anfis, fis_fmin};

    rom = zeros(512, 1);
    for s = 1:4
        rom((s-1)*128 + (1:128)) = cuantizar(conjuntos{s});
    end
    rom = uint16(rom);

    carpeta = fullfile('..', 'rom');
    if ~exist(carpeta, 'dir')
        mkdir(carpeta);
    end
    escribir_hex(fullfile(carpeta, 'parametros.hex'), rom);
    escribir_mif(fullfile(carpeta, 'parametros.mif'), rom);
    fprintf('ROM escrita en %s (parametros.hex y parametros.mif)\n', carpeta);
end

% ----------------------------------------------------------------------------

function fis = corregir(fis, nombre)
%CORREGIR Valida la estructura del FIS y corrige lo que el hardware no admite.

    rangos = [0 63; 0 63; 0 30];

    if numel(fis.Inputs) ~= 3 || numel(fis.Outputs) ~= 1
        error('FIS %s: se esperan 3 entradas y 1 salida.', nombre);
    end
    if ~strcmp(fis.AndMethod, 'prod') || ~strcmp(fis.DefuzzificationMethod, 'wtaver')
        error('FIS %s: se requiere AND = prod y salida wtaver.', nombre);
    end

    for j = 1:3
        if any(fis.Inputs(j).Range ~= rangos(j, :))
            warning('FIS %s: rango de la entrada %d ajustado a [%d %d].', ...
                    nombre, j, rangos(j, 1), rangos(j, 2));
            fis.Inputs(j).Range = rangos(j, :);
        end
        mfs = fis.Inputs(j).MembershipFunctions;
        if numel(mfs) ~= 3
            error('FIS %s: la entrada %d debe tener 3 funciones.', nombre, j);
        end
        for m = 1:3
            if ~strcmp(mfs(m).Type, 'trimf')
                error('FIS %s: la función %d de la entrada %d no es trimf.', nombre, m, j);
            end
            p = mfs(m).Parameters;
            if any(diff(p) < 0)
                warning('FIS %s: vértices de la función %d de la entrada %d reordenados.', ...
                        nombre, m, j);
                fis.Inputs(j).MembershipFunctions(m).Parameters = sort(p);
            end
        end
    end

    % Reglas: deben estar las 27 combinaciones, con AND y peso 1
    if numel(fis.Rules) ~= 27
        error('FIS %s: se esperan 27 reglas.', nombre);
    end
    vistas = false(27, 1);
    for r = 1:27
        regla = fis.Rules(r);
        ant = regla.Antecedent;
        if any(ant < 1) || any(ant > 3) || regla.Connection ~= 1 || regla.Weight ~= 1
            error('FIS %s: la regla %d no es compatible con el hardware.', nombre, r);
        end
        idx = 9*(ant(1)-1) + 3*(ant(2)-1) + ant(3);
        if vistas(idx)
            error('FIS %s: la combinación de la regla %d está repetida.', nombre, r);
        end
        vistas(idx) = true;

        mf = fis.Outputs(1).MembershipFunctions(regla.Consequent);
        if ~strcmp(mf.Type, 'constant')
            error('FIS %s: el consecuente de la regla %d no es constante.', nombre, r);
        end
        if mf.Parameters < 0 || mf.Parameters > 63
            warning('FIS %s: consecuente de la regla %d (%.2f s) limitado a [0 63].', ...
                    nombre, r, mf.Parameters);
            fis.Outputs(1).MembershipFunctions(regla.Consequent).Parameters = ...
                min(max(mf.Parameters, 0), 63);
        end
    end
end

function palabras = cuantizar(fis)
%CUANTIZAR Convierte un FIS ya corregido en las 128 palabras de su conjunto.

    palabras = zeros(128, 1);
    rangos = [0 63; 0 63; 0 30];

    for j = 1:3
        suma = zeros(1, rangos(j, 2) + 1);    % pertenencia total por entero
        for m = 1:3
            p = round(fis.Inputs(j).MembershipFunctions(m).Parameters * 256);
            if any(p < -32768) || any(p > 32767)
                error('Vértices fuera del rango de Q8.8: [%g %g %g]', p / 256);
            end
            il = reciproco(p(2) - p(1));
            ir = reciproco(p(3) - p(2));
            base = ((j-1)*3 + (m-1)) * 5;
            palabras(base + (1:5)) = [mod(p(1:3), 65536) il ir];

            for x = rangos(j, 1):rangos(j, 2)
                suma(x+1) = suma(x+1) + pertenencia(x*256, p(1), p(2), p(3), il, ir);
            end
        end
        if any(suma == 0)
            x = find(suma == 0, 1) - 1;
            error('La entrada %d no tiene ninguna función activa en x = %d.', j, x);
        end
    end

    for r = 1:27
        regla = fis.Rules(r);
        ant = regla.Antecedent - 1;
        z = fis.Outputs(1).MembershipFunctions(regla.Consequent).Parameters;
        palabras(46 + 9*ant(1) + 3*ant(2) + ant(3)) = round(z * 256);
    end
end

function inv = reciproco(d)
%RECIPROCO 1/d en Q0.16, con d en Q8.8. Un lado de ancho cero nunca se usa.
    if d == 0
        inv = 0;
    else
        inv = round(2^24 / d);
        if inv > 65535
            warning('Un lado de una función mide menos de 1; recíproco saturado.');
            inv = 65535;
        end
    end
end

function mu = pertenencia(x, a, b, c, il, ir)
%PERTENENCIA Igual que en fuzzy_punto_fijo.m.
    if x <= a || x >= c
        mu = 0;
    elseif x <= b
        mu = min(floor((x - a) * il / 256), 65535);
    else
        mu = min(floor((c - x) * ir / 256), 65535);
    end
end

function escribir_hex(archivo, rom)
    f = fopen(archivo, 'w');
    fprintf(f, '%04X\n', rom);
    fclose(f);
end

function escribir_mif(archivo, rom)
    f = fopen(archivo, 'w');
    fprintf(f, '-- Parametros del controlador difuso (generado por exportar_parametros.m)\n');
    fprintf(f, 'WIDTH=16;\nDEPTH=%d;\nADDRESS_RADIX=UNS;\nDATA_RADIX=HEX;\n\n', numel(rom));
    fprintf(f, 'CONTENT BEGIN\n');
    for i = 1:numel(rom)
        fprintf(f, '    %d : %04X;\n', i-1, rom(i));
    end
    fprintf(f, 'END;\n');
    fclose(f);
end
