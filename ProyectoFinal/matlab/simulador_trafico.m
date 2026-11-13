function [traza, res] = simulador_trafico(escenario, n_seg, controlador)
%SIMULADOR_TRAFICO Réplica de rtl/traffic_gen.v, rtl/acceso.v y rtl/traffic_fsm.v.
%
%   [traza, res] = simulador_trafico(escenario, n_seg)
%   [traza, res] = simulador_trafico(escenario, n_seg, controlador)
%
%   escenario    0 a 7 (Tabla 1 del README)
%   n_seg        segundos simulados
%   controlador  función @(x1, x2, x3) que devuelve la duración del verde en
%                segundos. Por omisión, tiempo fijo de 20 s.
%
%   traza  matriz n_seg x 8 con el mismo formato que tb/tb_semaforo.v:
%          [escenario segundo fase t_restante colaN colaS colaE colaO]
%          Cada fila es el estado antes de aplicar el segundo correspondiente.
%   res    estructura con métricas de la corrida.
%
%   Cualquier cambio en el Verilog debe reflejarse aquí y viceversa; la
%   comparación se hace con comparar_trazas.m.

    if nargin < 3
        controlador = @(x1, x2, x3) 20;
    end

    % Duraciones (iguales a traffic_fsm.v)
    T_AMARILLO = 3;  T_ROJO = 1;  T_MIN = 5;  T_MAX = 40;

    % Estados
    NS_VERDE = 1;  NS_AMARILLO = 2;  EO_VERDE = 3;  EO_AMARILLO = 4;
    ROJO_1 = 5;    ROJO_2 = 6;       % rojo total; en la traza se escriben como 0

    % Estado inicial (igual al reinicio del Verilog)
    lfsr      = [44257 7559 23359 58052];   % 0xACE1 0x1D87 0x5B3F 0xE2C4
    cola      = zeros(1, 4);                % [N S E O]
    historial = zeros(4, 30);               % columna 1: segundo más reciente
    lleg30    = zeros(1, 4);
    alterna   = zeros(1, 4);
    seg_ciclo = 0;
    estado    = ROJO_2;
    t_rest    = T_ROJO;

    traza = zeros(n_seg, 8);
    res = struct('demora_total', 0, 'atendidos', 0, 'llegadas', 0, ...
                 'rechazados', 0, 'cola_max', 0, 'verdes', zeros(0, 2));

    for k = 0:n_seg-1
        if estado == ROJO_1 || estado == ROJO_2
            fase = 0;
        else
            fase = estado;
        end
        traza(k+1, :) = [escenario k fase t_rest cola];

        % ---------------- Generador de tráfico ----------------
        umbral = umbrales_escenario(escenario, seg_ciclo);
        verde  = [estado == NS_VERDE, estado == NS_VERDE, ...
                  estado == EO_VERDE, estado == EO_VERDE];

        for i = 1:4
            lfsr(i) = lfsr16(lfsr(i));
            arr = lfsr(i) < umbral(i);
            dep = verde(i) && alterna(i) && cola(i) > 0;

            if verde(i)
                alterna(i) = ~alterna(i);
            else
                alterna(i) = 0;
            end

            lleg30(i) = lleg30(i) + arr - historial(i, 30);
            historial(i, :) = [arr historial(i, 1:29)];

            if arr && ~dep
                if cola(i) < 63
                    cola(i) = cola(i) + 1;
                else
                    res.rechazados = res.rechazados + 1;
                end
            elseif dep && ~arr
                cola(i) = cola(i) - 1;
            end

            res.llegadas  = res.llegadas + arr;
            res.atendidos = res.atendidos + dep;
        end

        seg_ciclo = mod(seg_ciclo + 1, 1800);
        res.demora_total = res.demora_total + sum(cola);
        res.cola_max     = max(res.cola_max, max(cola));

        % ---------------- Máquina de estados ----------------
        if t_rest > 1
            t_rest = t_rest - 1;
        else
            switch estado
                case NS_VERDE
                    estado = NS_AMARILLO;  t_rest = T_AMARILLO;
                case NS_AMARILLO
                    estado = ROJO_1;       t_rest = T_ROJO;
                case ROJO_1                % solicita el verde E-O
                    x1 = max(cola(3), cola(4));
                    x2 = max(cola(1), cola(2));
                    x3 = max(lleg30(3), lleg30(4));
                    t_rest = limita(controlador(x1, x2, x3), T_MIN, T_MAX);
                    estado = EO_VERDE;
                    res.verdes(end+1, :) = [EO_VERDE t_rest];
                case EO_VERDE
                    estado = EO_AMARILLO;  t_rest = T_AMARILLO;
                case EO_AMARILLO
                    estado = ROJO_2;       t_rest = T_ROJO;
                otherwise                  % ROJO_2: solicita el verde N-S
                    x1 = max(cola(1), cola(2));
                    x2 = max(cola(3), cola(4));
                    x3 = max(lleg30(1), lleg30(2));
                    t_rest = limita(controlador(x1, x2, x3), T_MIN, T_MAX);
                    estado = NS_VERDE;
                    res.verdes(end+1, :) = [NS_VERDE t_rest];
            end
        end
    end

    res.demora_promedio = res.demora_total / max(res.atendidos, 1);
end

function t = limita(t, t_min, t_max)
%LIMITA Redondea al segundo entero y limita al intervalo permitido.
    t = min(max(round(t), t_min), t_max);
end
