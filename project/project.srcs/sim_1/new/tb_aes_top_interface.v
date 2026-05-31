`timescale 1ns / 1ps

module tb_aes_top_interface();

    // Sinais de Conexão
    reg clk;
    reg reset;
    reg uart_pc_rx;
    reg uart_cmod_rx;
    wire uart_pc_tx;
    wire led_ready;
    wire led_heartbeat;
    wire led_busy;

    // Período para 115200 baud (1/115200 * 1e9 ns)
    localparam BIT_PERIOD = 8680; 

    // Instanciação do Módulo Top Corrigido
    aes_top_interface dut (
        .clk(clk),
        .reset(reset),
        .uart_pc_rx(uart_pc_rx),
        .uart_pc_tx(uart_pc_tx),
        .uart_cmod_rx(uart_cmod_rx),
        .led_ready(led_ready),
        .led_heartbeat(led_heartbeat),
        .led_busy(led_busy)
    );

    // Gerador de Clock 100MHz
    always #5 clk = ~clk;

    // --- Task para enviar para a CMOD (Chave) ---
    task send_to_cmod(input [7:0] data);
        integer i;
        begin
            uart_cmod_rx = 0; #(BIT_PERIOD); // Start
            for (i = 0; i < 8; i = i + 1) begin
                uart_cmod_rx = data[i]; #(BIT_PERIOD);
            end
            uart_cmod_rx = 1; #(BIT_PERIOD); // Stop
        end
    endtask

    // --- Task para enviar para o PC (Texto) ---
    task send_to_pc(input [7:0] data);
        integer i;
        begin
            uart_pc_rx = 0; #(BIT_PERIOD); // Start
            for (i = 0; i < 8; i = i + 1) begin
                uart_pc_rx = data[i]; #(BIT_PERIOD);
            end
            uart_pc_rx = 1; #(BIT_PERIOD); // Stop
        end
    endtask

    initial begin
        // Inicialização
        clk = 0;
        reset = 1;
        uart_pc_rx = 1;
        uart_cmod_rx = 1;
        
        #100 reset = 0;
        #200;

        $display("--- Iniciando Simulação: Interface Final ---");

        // 1. Envio da Chave (CMOD -> Basys)
        // Ordem: MSB para LSB para coincidir com o shift: {reg[119:0], data}
        $display("[%0t] Enviando Chave...", $time);
        send_to_cmod(8'h0f); send_to_cmod(8'h15); send_to_cmod(8'h71); send_to_cmod(8'hc9);
        send_to_cmod(8'h47); send_to_cmod(8'hd9); send_to_cmod(8'he8); send_to_cmod(8'h59);
        send_to_cmod(8'h0c); send_to_cmod(8'hb7); send_to_cmod(8'had); send_to_cmod(8'hd6);
        send_to_cmod(8'haf); send_to_cmod(8'h7f); send_to_cmod(8'h67); send_to_cmod(8'h98);

        wait(led_ready == 1);
        $display("[%0t] Chave carregada com sucesso!", $time);

        // 2. Envio do Texto (PC -> Basys)
        $display("[%0t] Enviando Texto Claro...", $time);
        send_to_pc(8'h01); send_to_pc(23); send_to_pc(8'h45); send_to_pc(8'h67);
        send_to_pc(8'h89); send_to_pc(8'hab); send_to_pc(8'hcd); send_to_pc(8'hef);
        send_to_pc(8'hfe); send_to_pc(8'hdc); send_to_pc(8'hba); send_to_pc(8'h98);
        send_to_pc(8'h76); send_to_pc(8'h54); send_to_pc(8'h32); send_to_pc(8'h10);

        // 3. Monitoramento
        $display("[%0t] Aguardando processamento AES...", $time);
        wait(led_busy == 1);
        wait(led_busy == 0);
        $display("[%0t] Cifragem finalizada. Monitorando TX de retorno...", $time);

        // Aguarda tempo suficiente para a UART devolver os 16 bytes (16 * 10 bits * BIT_PERIOD)
        #(16 * 10 * BIT_PERIOD);
        
        $display("--- Simulação Concluída ---");
        $finish;
    end

endmodule