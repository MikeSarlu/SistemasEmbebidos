`timescale 1ns/1ps
module tb_top_uart;
    reg  CLOCK_50 = 0;
    reg  RESET_N  = 0;
    reg  UART_RX  = 1;
    wire UART_TX;

    localparam BIT_NS = 104160;   // 5208 ciclos * 20 ns

    top_uart_de10lite dut (
        .CLOCK_50(CLOCK_50),
        .RESET_N(RESET_N),
        .UART_RX(UART_RX),
        .UART_TX(UART_TX)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    task send_byte(input [7:0] b);
        integer i;
        begin
            UART_RX = 0; #(BIT_NS);                       // start
            for (i = 0; i < 8; i = i + 1) begin
                UART_RX = b[i]; #(BIT_NS);                // datos, LSB primero
            end
            UART_RX = 1; #(BIT_NS);                       // stop
        end
    endtask

    initial begin
        #200 RESET_N = 1;
        #(BIT_NS);
        send_byte(8'd10);   #(BIT_NS*12);   // esperado: 11
        send_byte(8'd100);  #(BIT_NS*12);   // esperado: 101
        send_byte(8'd255);  #(BIT_NS*12);   // esperado: 0
        $stop;
    end
endmodule