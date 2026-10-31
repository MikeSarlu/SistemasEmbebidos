// PC envía [A][n]  ->  FPGA responde 13 bytes (MSB primero): A^(n/2) en Q80.20
// (100 bits, con 4 ceros de relleno arriba = 104 bits). MATLAB valida n <= 20.
module top_uart_de10lite #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire CLOCK_50,
    input  wire RESET_N,
    input  wire UART_RX,
    output wire UART_TX
);
    wire reset = ~RESET_N;

    wire [7:0] rx_data;
    wire       rx_done;
    reg  [7:0] tx_data;
    reg        tx_start;
    wire       tx_busy;

    reg         calc_start;
    wire        calc_done;
    wire [99:0] calc_result;
    reg  [7:0]  a_reg, n_reg;

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) RX0 (
        .clk(CLOCK_50), .reset(reset), .rx(UART_RX),
        .data_out(rx_data), .data_valid(rx_done));

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) TX0 (
        .clk(CLOCK_50), .reset(reset), .tx_start(tx_start),
        .data_in(tx_data), .tx(UART_TX), .busy(tx_busy));

    pow_half_q20 POW0 (
        .clk(CLOCK_50), .rst(reset), .start(calc_start),
        .a(a_reg), .n(n_reg), .done(calc_done), .result(calc_result));

    localparam S_A = 3'd0, S_N = 3'd1, S_CALC = 3'd2,
               S_LOAD = 3'd3, S_WAIT = 3'd4, S_BUSY = 3'd5;

    reg [2:0]   state;
    reg [3:0]   idx;
    reg [103:0] res_sh;

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            state <= S_A; idx <= 0; res_sh <= 0;
            tx_data <= 0; tx_start <= 0; calc_start <= 0;
            a_reg <= 0; n_reg <= 0;
        end else begin
            tx_start   <= 1'b0;
            calc_start <= 1'b0;
            case (state)
                S_A: if (rx_done) begin
                    a_reg <= rx_data;
                    state <= S_N;
                end

                S_N: if (rx_done) begin
                    n_reg      <= rx_data;
                    calc_start <= 1'b1;
                    state      <= S_CALC;
                end

                S_CALC: if (calc_done) begin
                    res_sh <= {4'd0, calc_result};
                    idx    <= 0;
                    state  <= S_LOAD;
                end

                S_LOAD: begin
                    tx_data  <= res_sh[103:96];      // MSB primero
                    tx_start <= 1'b1;
                    state    <= S_WAIT;
                end

                S_WAIT: state <= S_BUSY;

                S_BUSY: if (!tx_busy) begin
                    if (idx == 4'd12) state <= S_A;
                    else begin
                        res_sh <= {res_sh[95:0], 8'd0};
                        idx    <= idx + 1;
                        state  <= S_LOAD;
                    end
                end

                default: state <= S_A;
            endcase
        end
    end
endmodule
