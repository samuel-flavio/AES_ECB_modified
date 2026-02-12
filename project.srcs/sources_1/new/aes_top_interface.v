module aes_top_interface #(
    parameter [127:0] DEFAULT_KEY = 128'h0f1571c9_47d9e859_0cb7add6_af7f6798
) (
    input clk,             // 100MHz da Basys 3
    input rx_pc,           // Entrada UART         
    input reset,           // rst geral FPGA
    output tx,             // Saída UART
    output [1:0] led       // LEDs para diagnóstico
);

    // --- Sinais ---
    wire rx_done_pc, tx_ready;
    wire [7:0] rx_data_pc;
    reg [7:0] tx_data;
    reg tx_start;
    
    // --- Sinais AES ---
    reg aes_start;
    wire aes_busy, aes_done;
    wire [127:0] aes_out;

    // Sinais para detecção de borda no RX
    reg rx_done_pc_prev;
    
    // Buffers e contadores
    reg [127:0] data_buffer;        // Armazena os 16 bytes de dados
    reg [5:0] count;                // Contador de bytes
    
    // --- MODULOS UART ---
    // Recepcao PC 
    uart_rx #(.CLK_FREQ(100_000_000), .BAUD_RATE(921_600)) uart_pc (
        .clk(clk), .rst(reset), .rx(rx_pc), .data(rx_data_pc), .done(rx_done_pc)
    );

    // Transmissao PC
    uart_tx #(.CLK_FREQ(100_000_000), .BAUD_RATE(921_600)) my_tx (
        .clk(clk), .rst(reset), .start(tx_start), .data_in(tx_data), .tx(tx), .ready(tx_ready)
    );

    // INSTANCIA BLOCO DE CIFRAR
    aes_cipher my_aes (
        .clk(clk),
        .reset(reset),
        .start(aes_start),
        .plaintext(data_buffer),
        .initial_key(DEFAULT_KEY),
        .ciphertext(aes_out),
        .busy(aes_busy),
        .done(aes_done)
    );

    // --- MAQUINA DE ESTADOS ---
    reg [1:0] state;
    localparam  IDLE            = 3'b000,
                RECEIVE_DATA    = 3'b001,
                PROCESS         = 3'b010, 
                SEND            = 3'b011;

    // Processo FSM
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
            tx_start <= 0;
            rx_done_pc_prev <= 0;
        end else begin
            rx_done_pc_prev <= rx_done_pc;

            case (state)
                IDLE: begin
                    count <= 0;
                    tx_start <= 0;

                    if (rx_done_pc && !rx_done_pc_prev) begin
                        data_buffer <= {data_buffer[119:0], rx_data_pc};
                        count <= 1;
                        state <= RECEIVE_DATA;
                    end
                end 

                RECEIVE_DATA: begin
                    if (rx_done_pc && !rx_done_pc_prev) begin
                        data_buffer <= {data_buffer[119:0], rx_data_pc}; 
                        if (count == 15) begin
                            state <= PROCESS;
                            aes_start <= 1;
                        end else count <= count + 1;
                    end
                end

                PROCESS: begin
                    aes_start <= 0;
                    if (aes_done) begin
                        state <= SEND;
                        count <= 0;
                        data_buffer <= aes_out;
                    end
                end

                SEND: begin
                    if (tx_ready && !tx_start) begin
                        tx_data <= data_buffer[127:120];
                        tx_start <= 1;
                    end else if (tx_start && !tx_ready) begin
                        tx_start <= 0;
                        data_buffer <= {data_buffer[119:0], 8'h00};
                        if (count == 15) begin
                            count <= 0;
                            state <= IDLE;
                        end else count <= count + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign led = state; // LEDs mostram o estado atual
endmodule