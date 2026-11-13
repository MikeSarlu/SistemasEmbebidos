function u = umbrales_escenario(escenario, seg_ciclo)
%UMBRALES_ESCENARIO Umbrales de llegada [N S E O] de un escenario.
%   Los umbrales son round(p * 65536), con p la probabilidad de llegada por
%   segundo de la Tabla 1 del README. Equivale a la tabla de rtl/traffic_gen.v.
%
%   seg_ciclo es el segundo dentro del ciclo de 30 min (0 a 1799). Solo se usa
%   en el escenario 7, que alterna entre los escenarios 3 y 4 cada 900 s.

    P03 = 1966;  P05 = 3277;  P08 = 5243;  P10 = 6554;  P12 = 7864;
    P15 = 9830;  P18 = 11796; P20 = 13107; P22 = 14418; P25 = 16384;

    if escenario == 7
        if seg_ciclo < 900
            escenario = 3;
        else
            escenario = 4;
        end
    end

    switch escenario
        case 0, u = [P05 P05 P05 P05];   % baja uniforme
        case 1, u = [P12 P12 P12 P12];   % media uniforme
        case 2, u = [P18 P18 P18 P18];   % alta uniforme
        case 3, u = [P20 P20 P05 P05];   % calle principal N-S
        case 4, u = [P05 P05 P20 P20];   % calle principal E-O
        case 5, u = [P25 P03 P10 P10];   % un acceso cargado
        case 6, u = [P22 P15 P15 P08];   % hora pico asimétrica
        otherwise, u = [P05 P05 P05 P05];
    end
end
