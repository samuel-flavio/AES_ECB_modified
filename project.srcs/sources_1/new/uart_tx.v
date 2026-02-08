module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input rst,
    input start,           // Pulso para iniciar a transmissão de 1 byte
    input [7:0] data_in,   // O byte que queremos enviar
    output reg tx,         // Pino físico A18 da Basys 3
    output reg ready       // Indica que o transmissor está livre para o próximo byte
);

    localparam DVSR = CLK_FREQ / (BAUD_RATE * 16);
    
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state;
    reg [3:0] s_reg;      // Contador de ticks (0-15)
    reg [2:0] n_reg;      // Contador de bits (0-7)
    reg [7:0] b_reg;      // Registrador de deslocamento para o dado
    reg [15:0] tick_count;
    wire tick;

    // Mesmo Gerador de Baud Rate
    assign tick = (tick_count == DVSR);
    always @(posedge clk) begin
        if (rst || tick) tick_count <= 0;
        else             tick_count <= tick_count + 1;
    end

    // FSM de Transmissão
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1;   // Linha UART em repouso fica em '1'
            ready <= 1;
        end else begin
            ready <= 0;
            case (state)
                IDLE: begin
                    ready <= 1;
                    tx <= 1'b1;
                    if (start) begin
                        b_reg <= data_in;
                        s_reg <= 0;
                        state <= START;
                    end
                end
                START: begin
                    tx <= 1'b0; // Bit de Start
                    if (tick) begin
                        if (s_reg == 15) begin
                            state <= DATA;
                            s_reg <= 0;
                            n_reg <= 0;
                        end else s_reg <= s_reg + 1;
                    end
                end
                DATA: begin
                    tx <= b_reg[0]; // Envia o LSB
                    if (tick) begin
                        if (s_reg == 15) begin
                            s_reg <= 0;
                            b_reg <= b_reg >> 1;
                            if (n_reg == 7) state <= STOP;
                            else n_reg <= n_reg + 1;
                        end else s_reg <= s_reg + 1;
                    end
                end
                STOP: begin
                    tx <= 1'b1; // Bit de Stop
                    if (tick) begin
                        if (s_reg == 15) state <= IDLE;
                        else s_reg <= s_reg + 1;
                    end
                end
            endcase
        end
    end
endmodule