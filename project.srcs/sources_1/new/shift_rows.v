module shift_rows (
    input  [127:0] data_in,
    output [127:0] data_out
);

    // Mapeamento dos bytes do State (s_linha_coluna)
    // Coluna 0: bits 127:96
    // Coluna 1: bits 95:64
    // Coluna 2: bits 63:32
    // Coluna 3: bits 31:0

    // Linha 0 (Sem alteração)
    assign data_out[127:120] = data_in[127:120]; // s0,0
    assign data_out[95:88]   = data_in[95:88];   // s0,1
    assign data_out[63:56]   = data_in[63:56];   // s0,2
    assign data_out[31:24]   = data_in[31:24];   // s0,3

    // Linha 1 (Shift Left 1)
    assign data_out[119:112] = data_in[87:80];   // s1,0 <- s1,1
    assign data_out[87:80]   = data_in[55:48];   // s1,1 <- s1,2
    assign data_out[55:48]   = data_in[23:16];   // s1,2 <- s1,3
    assign data_out[23:16]   = data_in[119:112]; // s1,3 <- s1,0
    

    // Linha 2 (Shift Left 2)
    assign data_out[111:104] = data_in[47:40];    // s2,0 <- s2,2
    assign data_out[79:72]   = data_in[15:8];     // s2,1 <- s2,3
    assign data_out[47:40]   = data_in[111:104];  // s2,2 <- s2,0
    assign data_out[15:8]    = data_in[79:72];    // s2,3 <- s2,1
    
    // Linha 3 (Shift Left 3 ou Shift Right 1)
    assign data_out[103:96]  = data_in[7:0];     // s3,0 <- s3,3
    assign data_out[71:64]   = data_in[103:96];  // s3,1 <- s3,0
    assign data_out[39:32]   = data_in[71:64];   // s3,2 <- s3,1
    assign data_out[7:0]     = data_in[39:32];   // s3,3 <- s3,2
endmodule