function [t_q, t_v] = fuzzy_punto_fijo(rom, conjunto, x1, x2, x3)
%FUZZY_PUNTO_FIJO Réplica exacta, bit a bit, de rtl/fuzzy_controller.v.
%
%   [t_q, t_v] = fuzzy_punto_fijo(rom, conjunto, x1, x2, x3)
%
%   rom       vector de 512 palabras de 16 bits (salida de exportar_parametros)
%   conjunto  0 a 3: tiempo fijo, manual, ANFIS, fminsearch
%   x1 x2 x3  entradas enteras (colas de 0 a 63, llegadas de 0 a 30)
%
%   t_q  duración del verde en Q8.8 (entero de 16 bits, segundos * 256)
%   t_v  duración redondeada al segundo, de 0 a 63; es lo que recibe la FSM
%
%   Formatos de la ROM (ver exportar_parametros.m):
%     a, b, c    Q8.8 con signo
%     1/(b-a), 1/(c-b)   Q0.16 sin signo
%     z          Q8.8 sin signo
%   Grados de pertenencia y pesos en Q0.16 (0 a 65535).
%
%   Todas las operaciones son enteras con truncamiento (floor), como los
%   corrimientos del Verilog. Cualquier cambio en uno debe hacerse en el otro.

    base = conjunto * 128;
    palabra = @(i) double(rom(base + i + 1));            % i desde 0
    consigno = @(v) v - 65536 * (v >= 32768);

    x = [x1 x2 x3] * 256;

    % Grados de pertenencia: mu(m, j) es la función m de la entrada j
    mu = zeros(3, 3);
    for j = 1:3
        for m = 1:3
            p  = ((j-1)*3 + (m-1)) * 5;
            a  = consigno(palabra(p));
            b  = consigno(palabra(p+1));
            c  = consigno(palabra(p+2));
            il = palabra(p+3);
            ir = palabra(p+4);
            mu(m, j) = pertenencia(x(j), a, b, c, il, ir);
        end
    end

    % Reglas en el orden de la ROM: x3 cambia más rápido
    acc_w  = 0;
    acc_wz = 0;
    k = 0;
    for m1 = 1:3
        for m2 = 1:3
            for m3 = 1:3
                z   = palabra(45 + k);
                w12 = floor(mu(m1, 1) * mu(m2, 2) / 65536);
                w   = floor(w12 * mu(m3, 3) / 65536);
                acc_w  = acc_w  + w;
                acc_wz = acc_wz + floor(w * z / 256);    % Q8.16
                k = k + 1;
            end
        end
    end

    if acc_w == 0
        t_q = 20 * 256;                                  % respaldo del Verilog
    else
        t_q = floor(acc_wz * 256 / acc_w);               % Q8.8
    end
    t_v = min(floor((t_q + 128) / 256), 63);
end

function mu = pertenencia(x, a, b, c, il, ir)
%PERTENENCIA Función triangular con recíprocos precalculados (Q0.16).
    if x <= a || x >= c
        mu = 0;
    elseif x <= b
        mu = min(floor((x - a) * il / 256), 65535);
    else
        mu = min(floor((c - x) * ir / 256), 65535);
    end
end
