`timescale 1ns / 1ps

module tb_add_round_key();

    reg  [127:0] state_in;
    reg  [127:0] round_key;
    wire [127:0] state_out;

    // Instanciação do módulo
    add_round_key dut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    initial begin
        $display("--- Teste AddRoundKey ---");

        // TESTE 1: XOR com Zero (Identidade)
        state_in  = 128'h0123456789ABCDEF0123456789ABCDEF;
        round_key = 128'h00000000000000000000000000000000;
        #10;
        $display("Teste 1 (Identidade): %s", (state_out == state_in) ? "PASSOU" : "FALHOU");

        // TESTE 2: XOR com o mesmo valor (Resultado deve ser Zero)
        state_in  = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        round_key = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #10;
        $display("Teste 2 (Auto-XOR):   %s", (state_out == 128'h0) ? "PASSOU" : "FALHOU");

        // TESTE 3: Valores do Exemplo Stallings (Parcial)
        // State após ShiftRows/MixColumns e a Round Key correspondente
        state_in  = 128'h473794ED_40D4E4A5_A3703AA6_4C9F42BC;
        round_key = 128'hAC7766F3_19FADC21_28D12941_575C006A;
        #10;
        // Esperado: A4927FF2689F352B6B5BE861023159D7
        $display("Teste 3 (Stallings Val):   %s", (state_out == 128'hEB40F21E_592E3884_8BA113E7_1BC342D6) ? "PASSOU" : "FALHOU");
        $display("Resultado Obteido: %h", state_out);

        #10 $finish;
    end
endmodule