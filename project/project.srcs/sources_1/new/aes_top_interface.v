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
    reg [159:0] out_buffer;         // Armazena os 16 bytes de dados e os 4 bytes de contagem
    reg [5:0] count;                // Contador de bytes
    
    // --- SINAIS KEY AGILITY ---
    reg [127:0] key_counter;
    reg [127:0] current_key;

    // Buffers para controle de execução dos ciclos do AES
    reg [31:0] cycle_counter; // Contador da quantidade de ciclos usados para processar o AES
    reg [31:0] final_cycles;  // Trava o valor para envio
    
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
        .initial_key(current_key),
        .ciphertext(aes_out),
        .busy(aes_busy),
        .done(aes_done)
    );

    // --- MAQUINA DE ESTADOS ---
    reg [2:0] state;
    localparam  IDLE            = 3'b000,
                RECEIVE_DATA    = 3'b001,
                WAIT_KEY        = 3'b010,
                PROCESS         = 3'b011, 
                SEND            = 3'b100;

    // Processo FSM
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
            tx_start <= 0;
            rx_done_pc_prev <= 0;
            key_counter <= ~128'd0; // Inicializa com todos os bits em 1 (0xFF...FF)
            current_key <= DEFAULT_KEY;
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
                            state <= WAIT_KEY;
                        end else count <= count + 1;
                    end
                end
                
                WAIT_KEY: begin
                    current_key <= DEFAULT_KEY ^ key_counter;
                    state <= PROCESS;
                    aes_start <= 1;
                end               

                PROCESS: begin
                    aes_start <= 0;
                    if (aes_done) begin
                        state <= SEND;
                        count <= 0;
                        out_buffer <= {aes_out, final_cycles};
                        key_counter <= key_counter - 1'b1; // Decrementa a cada bloco concluído
                    end
                end

                SEND: begin
                    if (tx_ready && !tx_start) begin
                        tx_data <= out_buffer[159:152];
                        tx_start <= 1;
                    end else if (tx_start && !tx_ready) begin
                        tx_start <= 0;
                        out_buffer <= {out_buffer[151:0], 8'h00};
                        if (count == 19) begin
                            count <= 0;
                            state <= IDLE;
                        end else count <= count + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    

    always @(posedge clk) begin
        if (reset) begin
            cycle_counter <= 0;
        end else if (aes_busy) begin
            cycle_counter <= cycle_counter + 1;
        end else if (aes_start) begin
            cycle_counter <= 0; // Reseta ao começar nova cifragem
        end else if (aes_done) begin
            final_cycles <= cycle_counter; // Salva o tempo gasto
        end
    end

    assign led = state[1:0]; // LEDs mostram o estado atual
endmodule