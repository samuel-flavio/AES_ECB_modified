module mix_columns (
    input  [127:0] data_in,
    output [127:0] data_out
);

    // Função xtime: Multiplicação por {02} no corpo finito GF(2^8)
    function [7:0] xtime;
        input [7:0] b;
        begin
            // Se o MSB for 1, desloca e faz XOR com o polinômio 8'h1b
            xtime = (b[7] == 1) ? ((b << 1) ^ 8'h1b) : (b << 1);
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : col_loop
            // Extração dos bytes da coluna i (Organização FIPS 197)
            // Lembre-se: O AES preenche o vetor coluna por coluna.
            // Coluna 0: [127:96], Coluna 1: [95:64], etc.
            wire [7:0] s0 = data_in[127 - (i*32) -: 8];
            wire [7:0] s1 = data_in[119 - (i*32) -: 8];
            wire [7:0] s2 = data_in[111 - (i*32) -: 8];
            wire [7:0] s3 = data_in[103 - (i*32) -: 8];

            // Multiplicação Matricial para cada byte da nova coluna:
            // s'0 = ({02}*s0) ^ ({03}*s1) ^ s2 ^ s3
            // s'1 = s0 ^ ({02}*s1) ^ ({03}*s2) ^ s3
            // s'2 = s0 ^ s1 ^ ({02}*s2) ^ ({03}*s3)
            // s'3 = ({03}*s0) ^ s1 ^ s2 ^ ({02}*s3)
            
            // Nota: {03}*s é implementado como (xtime(s) ^ s)
            
            assign data_out[127 - (i*32) -: 8] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
            assign data_out[119 - (i*32) -: 8] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
            assign data_out[111 - (i*32) -: 8] = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
            assign data_out[103 - (i*32) -: 8] = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);
        end
    endgenerate

endmodule