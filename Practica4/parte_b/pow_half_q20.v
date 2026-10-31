// result = floor( A^(n/2) * 2^20 )  en Q80.20 (100 bits)   A: 0..255, n: 0..20
module pow_half_q20 (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [7:0]   a,
    input  wire [7:0]   n,
    output reg          done,
    output reg  [99:0]  result
);
    localparam IDLE = 3'd0, MUL = 3'd1, PREP = 3'd2, SQRT = 3'd3, FIN = 3'd4;

    reg [2:0]   state;
    reg [7:0]   a_r;
    reg [4:0]   nleft;
    reg [159:0] p;          // A^k
    reg [199:0] rad;        // A^n * 2^40
    reg [103:0] rem;
    reg [99:0]  res;
    reg [6:0]   cnt;

    wire [103:0] rem_n = {rem[101:0], rad[199:198]};
    wire [103:0] trial = {2'b00, res, 2'b01};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE; done <= 1'b0; result <= 0;
            a_r <= 0; nleft <= 0; p <= 0; rad <= 0; rem <= 0; res <= 0; cnt <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) begin
                    a_r   <= a;
                    nleft <= n[4:0];
                    p     <= 160'd1;
                    state <= (n == 8'd0) ? PREP : MUL;
                end

                MUL: begin                       // p = p * A, n veces
                    p     <= p * a_r;
                    nleft <= nleft - 1'b1;
                    if (nleft == 5'd1) state <= PREP;
                end

                PREP: begin
                    rad <= {p, 40'd0};
                    rem <= 0; res <= 0; cnt <= 0;
                    state <= SQRT;
                end

                SQRT: begin                      // raíz entera, 100 iteraciones
                    if (rem_n >= trial) begin
                        rem <= rem_n - trial;
                        res <= {res[98:0], 1'b1};
                    end else begin
                        rem <= rem_n;
                        res <= {res[98:0], 1'b0};
                    end
                    rad <= {rad[197:0], 2'b00};
                    cnt <= cnt + 1'b1;
                    if (cnt == 7'd99) state <= FIN;
                end

                FIN: begin
                    result <= res;
                    done   <= 1'b1;
                    state  <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
