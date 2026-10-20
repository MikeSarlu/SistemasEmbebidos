module tick_generator (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire [2:0] speed_sel,
    output reg        tick
);

    reg [25:0] counter;
    reg [25:0] terminal_count;
    reg [2:0]  previous_speed;

    always @(*) begin
        case (speed_sel)
            3'b000: terminal_count = 26'd49_999;
            3'b001: terminal_count = 26'd7_185_713;
            3'b010: terminal_count = 26'd14_321_428;
            3'b011: terminal_count = 26'd21_457_142;
            3'b100: terminal_count = 26'd28_592_856;
            3'b101: terminal_count = 26'd35_728_570;
            3'b110: terminal_count = 26'd42_864_285;
            3'b111: terminal_count = 26'd49_999_999;
            default: terminal_count = 26'd49_999;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter        <= 26'd0;
            tick           <= 1'b0;
            previous_speed <= 3'b000;
        end else begin
            previous_speed <= speed_sel;
            tick <= 1'b0;

            if (!enable || (speed_sel != previous_speed)) begin
                counter <= 26'd0;
            end else if (counter >= terminal_count) begin
                counter <= 26'd0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 26'd1;
            end
        end
    end

endmodule
