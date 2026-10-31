clear
clc

PORT = "COM3";   % Cambiar por el puerto del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
s.Timeout = 2;
pause(2);
flush(s);

disp("Calcula A^(n/2) en Q80.20 (A: 0..255, n: 0..20). 'q' para salir.");

while true
    eA = input('A (0-255): ', 's');
    if strcmpi(eA, 'q'), break; end
    en = input('n (0-20): ', 's');
    if strcmpi(en, 'q'), break; end
    A = str2double(eA);  n = str2double(en);

    if isnan(A) || isnan(n) || A ~= round(A) || n ~= round(n) || A < 0 || A > 255 || n < 0 || n > 20
        disp('Valores invalidos: A entero 0..255, n entero 0..20');
        continue;
    end

    flush(s);
    write(s, uint8([A n]), "uint8");        % primero A, luego n

    t0 = tic;
    while s.NumBytesAvailable < 13 && toc(t0) < 2
        pause(0.005);
    end
    if s.NumBytesAvailable < 13
        disp('No se recibio respuesta completa (13 bytes)');
        continue;
    end

    b = read(s, 13, "uint8");               % MSB primero
    if b(1) == 255
        disp('La FPGA reporto error (n fuera de rango)');
        continue;
    end

    bits = reshape(dec2bin(b, 8).', 1, []); % 104 bits
    bits = bits(5:end);                     % quita 4 ceros de relleno -> 100 bits
    parteEntera = bits(1:80);
    parteFrac   = bits(81:100);

    fprintf('Q80.20 : %s.%s\n', parteEntera, parteFrac);
end

clear s
