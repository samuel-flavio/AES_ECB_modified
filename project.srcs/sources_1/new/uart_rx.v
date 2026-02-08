module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input rst,
    input rx,              // Pino físico B18 da Basys 3
    output reg [7:0] data, // Byte recebido
    output reg done        // Pulso de 1 ciclo indicando byte pronto
);

    localparam DVSR = CLK_FREQ / (BAUD_RATE * 16);
    
    // Estados da FSM de recepção
    localparam IDLE  = 2'b00, START = 2'b01, DATA  = 2'b10, STOP  = 2'b11;
    
    reg [1:0] state;
    reg [3:0] s_reg; // Contador de ticks (0-15)
    reg [2:0] n_reg; // Contador de bits (0-7)
    reg [7:0] b_reg; // Registrador de deslocamento para os bits
    reg [15:0] tick_count; // Gerador de baud rate
    wire tick;

    // Gerador de Ticks (Baud Rate Generator)
    assign tick = (tick_count == DVSR);
    always @(posedge clk) begin
        if (rst || tick) tick_count <= 0;
        else             tick_count <= tick_count + 1;
    end

    // FSM de Recepção
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            data <= 8'b0;
            
        end else begin
            done <= 0;
            
            if (tick) begin
                case (state)
                    IDLE: if (~rx) begin // Detectou Start Bit (0)
                        state <= START;
                        s_reg <= 0;
                    end
                    
                    START: if (s_reg == 7) begin // Meio do bit
                        state <= DATA;
                        s_reg <= 0;
                        n_reg <= 0;
                    end else s_reg <= s_reg + 1;
                    
                    DATA: if (s_reg == 15) begin // Amostra no centro
                        s_reg <= 0;
                        b_reg <= {rx, b_reg[7:1]}; // LSB primeiro
                        if (n_reg == 7) state <= STOP;
                        else n_reg <= n_reg + 1;
                    end else s_reg <= s_reg + 1;
                    
                    STOP: if (s_reg == 15) begin
                        state <= IDLE;
                    end else s_reg <= s_reg + 1;
                endcase
            end
            
            if (state == STOP && tick && s_reg == 15) begin
                data <= b_reg;
                done <= 1;
            end
        end
    end
endmodule