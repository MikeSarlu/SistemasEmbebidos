%GENERAR_PARAMETROS Etapa 2: ROM del controlador difuso y vectores de prueba.
%   Construye el FIS manual, lo cuantiza en ../rom/parametros.hex y
%   ../rom/parametros.mif, y genera ../tb/vectores_fuzzy.txt para
%   tb/tb_fuzzy_controller.v. Se ejecuta con matlab/ como carpeta actual.
%
%   Mientras no existan los FIS de ANFIS y fminsearch, los conjuntos 2 y 3 de
%   la ROM usan el manual. Cuando existan, se pasan como segundo y tercer
%   argumento de exportar_parametros.

fis = fis_manual();

fprintf('Consecuentes del FIS manual (s), x3 = baja / media / alta:\n');
etiquetas = {'baja', 'media', 'alta'};
for m1 = 1:3
    for m2 = 1:3
        k = 9*(m1-1) + 3*(m2-1) + (1:3);
        z = arrayfun(@(i) fis.Outputs(1).MembershipFunctions(i).Parameters, k);
        fprintf('  x1 %-5s  x2 %-5s : %5.1f %5.1f %5.1f\n', ...
                etiquetas{m1}, etiquetas{m2}, z);
    end
end
fprintf('\n');

[rom, conjuntos] = exportar_parametros(fis);
fprintf('\n');
vectores_prueba(rom, conjuntos);
