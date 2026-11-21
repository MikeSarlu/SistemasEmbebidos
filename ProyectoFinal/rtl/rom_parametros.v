// ROM de parámetros del controlador difuso: 512 palabras de 16 bits.
//
// Cuatro conjuntos de 128 palabras (tiempo fijo, manual, ANFIS y fminsearch).
// El contenido lo genera matlab/exportar_parametros.m en rom/parametros.hex.
// La lectura es síncrona (el dato aparece un ciclo después de la dirección)
// para que Quartus la implemente en un bloque M9K.
//
// ARCHIVO es relativo a la carpeta desde donde se compila o simula.

module rom_parametros #(
    parameter ARCHIVO = "../rom/parametros.hex"
)(
    input  wire        clk,
    input  wire [8:0]  dir,
    output reg  [15:0] dato
);

    reg [15:0] mem [0:511];

    initial $readmemh(ARCHIVO, mem);

    always @(posedge clk)
        dato <= mem[dir];

endmodule
