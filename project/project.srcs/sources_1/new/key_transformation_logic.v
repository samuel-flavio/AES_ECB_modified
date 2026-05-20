module key_transformation_logic (
    input  [31:0] word_in,   // w[i-1]
    input  [7:0]  rcon,      // Rcon da rodada atual
    input         clk,
    input         reset,
    input         en,        // Inicio do cálculo
    output [31:0] word_out,  // O valor 'temp' processado
    output reg    vld_out    // Indica o término do cálculo
);


    wire [31:0] rotated_word;
    wire [31:0] subbed_word;

    // 1. RotWord (Combinacional: apenas fios)
    assign rotated_word = {word_in[23:0], word_in[31:24]};

    // 2. SubWord (Síncrono: Usa 4 S-Boxes)
    // Aqui você instancia sua S-Box 4 vezes
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : subword_block
            sbox sbox_inst (
                .clk(clk),
                .addr(rotated_word[i*8 +: 8]),
                .data(subbed_word[i*8 +: 8])
            );
        end
    endgenerate

    // 3. Rcon XOR (Combinacional)
    // No AES, o XOR com Rcon só afeta o byte mais significativo (MSB)
    assign word_out = subbed_word ^ {rcon, 24'h000000};
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vld_out <= 1'b0;
        end else begin
            vld_out <= en; 
        end
    end
    
endmodule 