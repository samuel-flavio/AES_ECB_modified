module add_round_key (
    input  [127:0] state_in,    // Estado vindo da rodada anterior
    input  [127:0] round_key,   // Subchave da rodada atual
    output [127:0] state_out    // Estado após o XOR
);

    // Operação XOR bit a bit entre o State e a Chave
    // O operador '^' em Verilog aplica a lógica bit a bit em todo o vetor
    assign state_out = state_in ^ round_key;
endmodule