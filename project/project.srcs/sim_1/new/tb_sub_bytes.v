`timescale 1ns / 1ps

module tb_sub_bytes();

    // Sinais de teste
    reg clk;
    reg [127:0] state_in;
    wire [127:0] state_out;

    // Instanciação do módulo SubBytes
    sub_bytes dut (
        .clk(clk),
        .state_in(state_in),
        .state_out(state_out)
    );

    // Geração do clock (período de 10ns = 100MHz)
    always #5 clk = ~clk;

    initial begin
        // Inicialização
        clk = 0;
        state_in = 0;
        
        // Aguarda a estabilização do sistema
        #20;

        // --- TESTE 1: Vetor Aleatório ---
        // Gerando 128 bits (16 bytes) aleatórios
        state_in = { $random, $random, $random, $random };
        
        // Como o módulo sbox é síncrono (BRAM), 
        // o resultado aparece após a borda de subida do clock.
        @(posedge clk);
        #2; // Pequeno atraso para visualização estável
        
        $display("--- Teste SubBytes ---");
        $display("Entrada (Hex): %h", state_in);
        $display("Saída   (Hex): %h", state_out);
        
        // --- TESTE 2: Valores conhecidos (primeira linha da S-Box) ---
        #10;
        state_in = 128'h000102030405060708090A0B0C0D0E0F;
        
        @(posedge clk);
        #2;
        $display("\n--- Teste com Valores Sequenciais (00 a 0F) ---");
        $display("Entrada: %h", state_in);
        $display("Saída:   %h", state_out);
        $display("Esperado: 637c777bf26b6fc53001672bfed7ab76");

        #20;
        $finish;
    end

endmodule