//module aes_top_interface (
//    input  clk,              // 100 MHz da Basys 3
//    input  reset,            // Botão de Reset
//    // Interface UART PC (USB-UART)
//    input  uart_pc_rx,       // Pino B18
//    output uart_pc_tx,       // Pino A18
//    // Interface UART CMOD (Pmod JA)
//    input  uart_cmod_rx,     // Pino no JA (ex: J1)
//    // Indicadores Visuais
//    output led_ready,        // Aceso quando a chave foi carregada
//    output led_heartbeat,    // Pisca enquanto espera a chave da CMOD
//    output reg led_busy      // Aceso durante processamento/transmissão
//);

//    // --- Parâmetros de Estado da Interface ---
//    localparam S_WAIT_KEY    = 3'b000;
//    localparam S_WAIT_DATA   = 3'b001;
//    localparam S_PREPARE_AES = 3'B010; 
//    localparam S_RUN_AES     = 3'b011;
//    localparam S_SEND_DATA   = 3'b100;

//    reg [2:0] state;
//    reg [3:0] byte_count;
//    reg [127:0] key_reg;
//    reg [127:0] data_reg;
//    reg [31:0] heartbeat_cnt;
//    reg [127:0] out_buffer;
    
//    // Sinais para conectar ao SEU módulo aes_cipher
//    reg  aes_start;
//    wire aes_busy;
//    wire aes_done;
//    wire [127:0] aes_output;
////    wire [127:0] key = 128'h0f1571c947d9e8590cb7add6af7f6798;
    
//    // Sinais UARTs
//    wire [7:0] rx_pc_data, rx_cmod_data;
//    wire rx_pc_done, rx_cmod_done;
//    reg  tx_pc_start;
//    reg  [7:0] tx_pc_data;
//    wire tx_pc_ready;

//    // --- INSTÂNCIAS DAS UARTS ---
//    uart_rx #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) uart_pc_rx_u (
//        .clk(clk), .rst(reset), .rx(uart_pc_rx), .data(rx_pc_data), .done(rx_pc_done)
//    );

//    uart_tx #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) uart_pc_tx_u (
//        .clk(clk), .rst(reset), .start(tx_pc_start), .data_in(tx_pc_data), .tx(uart_pc_tx), .ready(tx_pc_ready)
//    );

//    uart_rx #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) uart_cmod_rx_u (
//        .clk(clk), .rst(reset), .rx(uart_cmod_rx), .data(rx_cmod_data), .done(rx_cmod_done)
//    );

//    // --- INSTÂNCIA DO SEU MÓDULO AES_CIPHER (Ajustado) ---
//    aes_cipher aes_core (
//        .clk(clk),
//        .reset(reset),
//        .start(aes_start),
//        .plaintext(data_reg),    // Mapeado para seu 'plaintext'
//        .initial_key(key_reg),  // Mapeado para seu 'initial_key'
//        .ciphertext(aes_output),// Mapeado para seu 'ciphertext'
//        .busy(aes_busy),        // Mapeado para seu 'busy'
//        .done(aes_done)         // Mapeado para seu 'done'
//    );

//    // --- FSM DE CONTROLE DA INTERFACE ---
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            state <= S_WAIT_KEY;
//            byte_count <= 0;
//            key_reg <= 128'h0;
//            data_reg <= 128'h0;
//            aes_start <= 0;
//            tx_pc_start <= 0;
//            led_busy <= 0;
//        end else begin
//            tx_pc_start <= 0; // Pulso padrão (1 ciclo)
            
//            case (state)
//                // 1. Recebe chave da CMOD S7 via Pmod
//                S_WAIT_KEY: begin
//                    if (rx_cmod_done) begin
//                        key_reg <= {key_reg[119:0], rx_cmod_data};
//                        if (byte_count == 15) begin
//                            byte_count <= 0;
//                            state <= S_WAIT_DATA;
//                        end else byte_count <= byte_count + 1;
//                    end
//                end

//                // 2. Recebe texto do PC via USB-UART
//                S_WAIT_DATA: begin
//                    if (rx_pc_done) begin
//                        data_reg <= {data_reg[119:0], rx_pc_data};
//                        if (byte_count == 15) begin
//                            byte_count <= 0;
//                            state <= S_PREPARE_AES;
//                        end else byte_count <= byte_count + 1;
//                    end
//                end

//                // 3. Aguarda o último bit subir ao buffer
//                S_PREPARE_AES: begin
//                    state <= S_RUN_AES;
//                end
//                // 4. Executa a cifragem
//                S_RUN_AES: begin
//                    led_busy <= 1;
//                    if (!aes_busy && !aes_done) begin
//                        aes_start <= 1;
//                    end else if (aes_done) begin
//                        aes_start <= 0;
//                        out_buffer <= aes_output; // Guarda o resultado para enviar
//                        state <= S_SEND_DATA;
//                        byte_count <= 0;
//                    end else begin
//                        aes_start <= 0; // Mantém start em 0 enquanto busy
//                    end
//                end

//                // 5. Envia o resultado de volta para o PC
//                S_SEND_DATA: begin
//                    if (tx_pc_ready && !tx_pc_start) begin
//                        tx_pc_data <= data_reg[127 - (byte_count * 8) -: 8];
//                        tx_pc_start <= 1;
//                    end else if (!tx_pc_ready) begin
//                        // Quando a UART começa a transmitir, podemos preparar o próximo byte
//                        if (tx_pc_start == 0) begin // Garante que o pulso já passou
//                             // Espera o sinal ready subir de novo para contar
//                        end
//                    end
                    
//                    // Lógica de incremento segura para UART_TX
//                    if (tx_pc_start) begin
//                        if (byte_count == 15) begin
//                            state <= S_WAIT_DATA; 
//                            byte_count <= 0;
//                            led_busy <= 0;
//                        end else begin
//                            byte_count <= byte_count + 1;
//                        end
//                    end
//                end
                
//                default: state <= S_WAIT_KEY;
//            endcase
//        end
//    end

//    // --- LÓGICA DE HEARTBEAT E LEDS ---
//    always @(posedge clk) heartbeat_cnt <= heartbeat_cnt + 1;
//    assign led_heartbeat = (state == S_WAIT_KEY) ? heartbeat_cnt[25] : 1'b0;
//    assign led_ready = (state != S_WAIT_KEY);

//endmodule

module aes_top_interface (
    input clk,          // 100MHz da Basys 3
    input rx,           // Entrada UART
    input reset,          // rst geral FPGA
    output tx,          // Saída UART
    output [1:0] led    // LEDs para diagnóstico
);

    // --- Sinais ---
    wire rx_done, tx_ready;
    wire [7:0] rx_data;
    reg [7:0] tx_data;
    reg tx_start, rx_done_prev;
    
    
    reg [127:0] buffer; // Armazena os 16 bytes
    reg [4:0] count;    // Contador de bytes
    
    // --- Módulos UART ---
    uart_rx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115_200)) my_rx (
        .clk(clk), .rst(reset), .rx(rx), .data(rx_data), .done(rx_done)
    );

    uart_tx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115_200)) my_tx (
        .clk(clk), .rst(reset), .start(tx_start), .data_in(tx_data), .tx(tx), .ready(tx_ready)
    );

    // --- Máquina de Estados ---
    reg [1:0] state;
    localparam RECEIVE = 2'b00, PROCESS = 2'b01, SEND = 2'b10;

    always @(posedge clk) begin
    rx_done_prev <= rx_done;
    
        case (state)
            RECEIVE: begin
                tx_start <= 0;
                if (rx_done && !rx_done_prev) begin
                    buffer <= {buffer[119:0], rx_data}; // Desloca e armazena
                    count <= count + 1;
                    if (count == 15) state <= PROCESS;
                end
            end

            PROCESS: begin
                // 5 ciclos para preparar o envio
                count <= count+1;
                if (count == 20) begin
                    state <= SEND;
                    count <= 0;
                end
            end

            SEND: begin
                if (tx_ready && !tx_start) begin
                    // Pega o byte mais significativo e soma 1
                    tx_data <= buffer[127:120] + 8'd1;
                    tx_start <= 1;
                end else if (tx_start) begin
                    if (!tx_ready) begin
                        tx_start <= 0;
                        buffer <= {buffer[119:0], 8'h00}; // Desloca para o próximo
                        if (count == 15) begin
                            count <= 0;
                            state <= RECEIVE;
                        end else count <= count + 1;
                    end
                end
            end
        endcase
    end

    assign led = state; // LEDs mostram o estado atual
endmodule
