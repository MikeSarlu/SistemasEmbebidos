function fis = fis_manual()
%FIS_MANUAL Controlador difuso Sugeno de orden cero con reglas a criterio.
%
%   fis = fis_manual()
%
%   Entradas (sección 5.3 del README):
%     x1  cola mayor de los dos accesos que reciben el verde   [0 63] veh
%     x2  cola mayor de los dos accesos que quedan en rojo     [0 63] veh
%     x3  llegadas recientes (30 s) de la fase que recibe el verde [0 30] veh
%   Salida:
%     t_verde  duración del verde [5 40] s
%
%   Cada entrada tiene tres funciones triangulares (baja, media, alta). Las
%   vecinas se cruzan en 0.5, de modo que los grados de cada entrada suman 1.
%   La función "alta" se prolonga más allá del rango para que no llegue a cero
%   en el extremo superior; como el modelo Sugeno normaliza entre la suma de
%   los pesos, esa pendiente no cambia el resultado cuando es la única activa.
%
%   Se usa el producto como AND y el promedio ponderado como salida, igual
%   que en ANFIS y en rtl/fuzzy_controller.v.

    fis = sugfis('Name', 'semaforo_manual');
    fis.AndMethod = 'prod';
    fis.DefuzzificationMethod = 'wtaver';

    % Con un flujo de descarga de 0.5 veh/s por acceso, desalojar una cola de
    % q vehículos toma unos 2q + 1 s. Una cola de 15 ya ocupa casi todo el
    % verde máximo, por eso las funciones de las colas se centran en 0, 15 y 30.
    fis = addInput(fis, [0 63], 'Name', 'x1');
    fis = addMF(fis, 'x1', 'trimf', [-15  0  15], 'Name', 'baja');
    fis = addMF(fis, 'x1', 'trimf', [  0 15  30], 'Name', 'media');
    fis = addMF(fis, 'x1', 'trimf', [ 15 30 120], 'Name', 'alta');

    fis = addInput(fis, [0 63], 'Name', 'x2');
    fis = addMF(fis, 'x2', 'trimf', [-15  0  15], 'Name', 'baja');
    fis = addMF(fis, 'x2', 'trimf', [  0 15  30], 'Name', 'media');
    fis = addMF(fis, 'x2', 'trimf', [ 15 30 120], 'Name', 'alta');

    % En los escenarios de la Tabla 1 llegan a lo más unos 8 vehículos en 30 s
    % por acceso, por eso las funciones de x3 se centran en 0, 5 y 10.
    fis = addInput(fis, [0 30], 'Name', 'x3');
    fis = addMF(fis, 'x3', 'trimf', [-5  0   5], 'Name', 'baja');
    fis = addMF(fis, 'x3', 'trimf', [ 0  5  10], 'Name', 'media');
    fis = addMF(fis, 'x3', 'trimf', [ 5 10  60], 'Name', 'alta');

    fis = addOutput(fis, [5 40], 'Name', 't_verde');

    % Criterio de las reglas: el verde crece con la cola que lo recibe (x1) y
    % con las llegadas recientes (x3), y se acorta cuando la otra calle tiene
    % una cola grande (x2). Cada regla tiene su propio consecuente, como en
    % ANFIS:  z = base(x1) + ajuste(x2) + ajuste(x3), limitado a [5 40] s.
    base_x1   = [ 6 22 36];   % baja, media, alta
    ajuste_x2 = [ 4  0 -6];
    ajuste_x3 = [-2  2  4];

    reglas = zeros(27, 6);
    k = 0;
    for m1 = 1:3
        for m2 = 1:3
            for m3 = 1:3
                k = k + 1;
                z = base_x1(m1) + ajuste_x2(m2) + ajuste_x3(m3);
                z = min(max(z, 5), 40);
                fis = addMF(fis, 't_verde', 'constant', z, ...
                            'Name', sprintf('z%02d', k));
                % [x1 x2 x3 salida peso conexión(1 = AND)]
                reglas(k, :) = [m1 m2 m3 k 1 1];
            end
        end
    end
    fis = addRule(fis, reglas);
end
