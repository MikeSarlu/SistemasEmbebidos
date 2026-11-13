function s = lfsr16(s)
%LFSR16 Avanza 16 pasos un LFSR de Galois de 16 bits.
%   Polinomio x^16 + x^14 + x^13 + x^11 + 1 (máscara 0xB400).
%   Equivale a la función lfsr16 de rtl/acceso.v.

    for k = 1:16
        if bitand(s, 1)
            s = bitxor(bitshift(s, -1), 46080);   % 0xB400
        else
            s = bitshift(s, -1);
        end
    end
end
