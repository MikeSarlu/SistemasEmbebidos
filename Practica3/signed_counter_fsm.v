module signed_counter_fsm (
    input  wire              clk,
    input  wire              reset,        // activo en alto
    input  wire              tick,
    input  wire              pause_pulse,
    input  wire              inc_pulse,
    input  wire              dec_pulse,
    output reg  signed [8:0] count,
    output reg  [1:0]        state
);
 
    localparam [1:0] S_PAUSE = 2'd0;
    localparam [1:0] S_UP    = 2'd1;
    localparam [1:0] S_DOWN  = 2'd2;
 
    reg [1:0] next_state;
 
    always @(*) begin
        next_state = state;                 // por defecto conserva el estado
        if      (pause_pulse) next_state = S_PAUSE;
        else if (inc_pulse)   next_state = S_UP;
        else if (dec_pulse)   next_state = S_DOWN;
    end
 
    always @(posedge clk or posedge reset) begin
        if (reset) state <= S_PAUSE;
        else       state <= next_state;
    end
 
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 9'sd0;
        else if (tick && !pause_pulse) begin   // una pausa en el mismo ciclo evita el ultimo cambio
            case (state)
                S_UP:    count <= count + 9'sd1;
                S_DOWN:  count <= count - 9'sd1;
                default: count <= count;
            endcase
        end
    end
 
endmodule