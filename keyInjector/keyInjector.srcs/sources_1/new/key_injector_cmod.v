module key_injector_cmod (
    input  clk,           // Clock de 12 MHz da CMOD S7
    input  btn,           // Botão para disparar o envio (BTN0)
    input  rst,           // Botão de reset
    output uart_tx        // Saída serial para a Basys 3 (Pmod JA1)

);
    // --- Parâmetros ---
    // Chave de 128 bits (Exemplo Stallings)
    reg [127:0] SECRET_KEY = 128'h0f1571c9_47d9e859_0cb7add6_af7f6798;

    // Configuração UART: 12MHz / (115200 * 16) ≈ 6.51
    // Usaremos o parâmetro no módulo uart_tx
    
    // --- Sinais Internos ---
    reg [4:0] byte_cnt;
    reg [7:0] current_byte;
    reg tx_start;
    wire tx_ready;
    
    // --- Lógica de Debounce do Botão ---
    // Como o clock é 12MHz, 1 milhão de ciclos = ~83ms (suficiente para o dedo)
    reg [19:0] debounce_cnt;
    reg btn_stable;
    reg btn_prev;
    wire btn_rising_edge;

    always @(posedge clk) begin
        if (rst) begin
            debounce_cnt <= 0;
            btn_stable <= 0;
        end else begin
            if (btn) begin
                if (debounce_cnt < 20'd1000000) debounce_cnt <= debounce_cnt + 1;
                else btn_stable <= 1;
            end else begin
                debounce_cnt <= 0;
                btn_stable <= 0;
            end
            btn_prev <= btn_stable;
        end
    end
    
    assign btn_rising_edge = btn_stable && !btn_prev;

    // --- Instância da UART TX ---
    uart_tx #(.CLK_FREQ(12_000_000), .BAUD_RATE(115_200)) tx_unit (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data_in(current_byte),
        .tx(uart_tx),
        .ready(tx_ready)
    );

    // --- Máquina de Estados (FSM) de Envio ---
    reg [1:0] state;
    localparam IDLE = 2'b00, SEND = 2'b01, WAIT = 2'b10;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    tx_start <= 0;
                    byte_cnt <= 0;
                    if (btn_rising_edge) state <= SEND;
                end

                SEND: begin
                    if (tx_ready && !tx_start) begin
                        // Seleciona o byte da chave (do mais significativo para o menos)
                        current_byte <= SECRET_KEY[127: 120];
                        SECRET_KEY <= {SECRET_KEY[119:0], 8'h00};
                        tx_start <= 1;
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    tx_start <= 0; // Pulso de apenas 1 ciclo
                    if (tx_ready && !tx_start) begin
                        if (byte_cnt == 15) begin
                            state <= IDLE;
                        end else begin
                            byte_cnt <= byte_cnt + 1;
                            state <= SEND;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule