																   module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        data_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    // Sincronizador de 2 FF (entrada asíncrona)
    reg rx_sync1, rx_sync2;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    reg [15:0] clk_count;
    reg [3:0]  bit_index;   // 0 = start, 1..8 = datos, 9 = stop
    reg [7:0]  rx_shift;
    reg        receiving;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_count  <= 0;
            bit_index  <= 0;
            rx_shift   <= 0;
            receiving  <= 1'b0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            if (!receiving) begin
                if (rx_sync2 == 1'b0) begin        // flanco de inicio
                    receiving <= 1'b1;
                    clk_count <= HALF_BIT;         // llegar a la mitad del start
                    bit_index <= 0;
                end
            end else begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;

                    if (bit_index == 0) begin
                        // Mitad del bit de inicio: verificar que siga en 0
                        if (rx_sync2 == 1'b1)
                            receiving <= 1'b0;     // falso start
                        else
                            bit_index <= 1;
                    end else if (bit_index <= 8) begin
                        // Mitad de cada bit de dato (LSB primero)
                        rx_shift  <= {rx_sync2, rx_shift[7:1]};
                        bit_index <= bit_index + 1;
                    end else begin
                        // Mitad del bit de paro
                        receiving <= 1'b0;
                        if (rx_sync2 == 1'b1) begin
                            data_out   <= rx_shift;
                            data_valid <= 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule