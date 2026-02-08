`timescale 1ns / 1ps

module tb_aes_cipher();

    reg clk;
    reg reset;
    reg start;
    reg [127:0] plaintext;
    reg [127:0] initial_key;
    
    wire [127:0] ciphertext;
    wire busy;
    wire done;

    // Instanciação do seu módulo Top-Level
    aes_cipher dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .plaintext(plaintext),
        .initial_key(initial_key),
        .ciphertext(ciphertext),
        .busy(busy),
        .done(done)
    );

    // Geração do Clock (100MHz - similar ao da Basys 3)
    always #5 clk = ~clk;

    initial begin
        // 1. Inicialização
        clk = 0;
        reset = 1;
        start = 0;
        plaintext = 128'h3243f6a8_885a308d_313198a2_e0370734;
        initial_key = 128'h2b7e1516_28aed2a6_abf71588_09cf4f3c;

        #20 reset = 0;
        #20 start = 1; // Pulso de início
        #10 start = 0;

        $display("--- Iniciando Criptografia AES-128 ---");
        $display("Plaintext: %h", plaintext);
        $display("Key:       %h", initial_key);

        // 2. Espera até que o processo termine
        // O tempo total deve ser por volta de 30-40 ciclos de clock 
        // devido à FSM e aos tempos de espera da BRAM.
        wait(done);

        // 3. Verificação do Resultado
        $display("\nCálculo Finalizado!");
        $display("Ciphertext: %h", ciphertext);
        
        if (ciphertext == 128'h3925841d_02dc09fb_dc118597_196a0b32) begin
            $display("\n[SUCESSO] O resultado coincide com o padrão FIPS 197!");
        end else begin
            $display("\n[ERRO] O resultado divergiu. Verifique as transições da FSM ou a ordem dos bytes.");
        end

        #50 $finish;
    end

endmodule