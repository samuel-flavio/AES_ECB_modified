`timescale 1ns/1ps

module tb_key_expansion();

    reg clk;
    reg reset;
    reg start;
    reg [3:0] round;
    reg [127:0] key_in;
    wire [127:0] key_out;
    wire ready;

    // Instanciação do módulo key_expansion
    key_expansion dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .round(round),
        .key_in(key_in),
        .key_out(key_out),
        .ready(ready)
    );

    // Geração do clock
    always #5 clk = ~clk;

    initial begin
        $display("--- Teste de Expansão de Chave (FIPS 197 Example) ---");

        // Inicialização
        clk = 0;
        reset = 1;
        start = 0;
        round = 0; // Para a rodada 0, a chave é a original
        key_in = 128'h0F1571C9_47D9E859_0CB7ADD6_AF7F6798; // Chave original (w0-w3)
        #10; reset = 0;
        $display("Reset desativado em: %t", $realtime);

        $display("\nChave Original (Round 0): %h", key_in);

        // --- Geração das Subchaves para as Rodadas 1 a 10 ---
        for (integer i = 1; i <= 10; i = i + 1) begin
            round = i;
            start = 1;
            #10; // Pulso de start
            start = 0;

            // Espera o módulo 'ready' sinalizar que a nova chave está pronta
            @(posedge clk); // Espera o estado WAIT_SBOX
            @(posedge clk); // Espera o estado CALCULATE
            @(posedge ready); // Espera a flag 'ready'
            #1; // Pequeno delay para visualização

            $display("\nRound %0d (Chave w%0d-w%0d): %h", i, i*4, (i*4)+3, key_out);
            
            // A chave expandida (key_out) da rodada atual se torna a key_in da próxima rodada
            key_in = key_out; 
            
            // Os valores esperados para as chaves w4-w7 (Round 1) são:
            // e0471b0747d9e8590cb7add6af7f6798 (w0-w3) -> e0471b07 d79e535e 7b498e28 d436edba
            // Então, a key_in para Round 1 deve ser 128'hE0471B07_D79E535E_7B498E28_D436EDBA
            
            // Nota: Os displays serão longos. Você pode comparar com as tabelas do FIPS.
        end

        #20 $finish;
    end

endmodule