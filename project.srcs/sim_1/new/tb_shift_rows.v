`timescale 1ns / 1ps

module tb_shift_rows();

    reg  [127:0] data_in;
    wire [127:0] data_out;

    // Instanciação do módulo
    shift_rows dut (
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        // Montando o State de entrada:
        // Coluna 0: 00, 10, 20, 30
        // Coluna 1: 01, 11, 21, 31
        // Coluna 2: 02, 12, 22, 32
        // Coluna 3: 03, 13, 23, 33
        data_in = 128'h00102030_01112131_02122232_03132333;

        #10;

        $display("--- Teste ShiftRows ---");
        $display("Entrada:\n%h %h %h %h\n%h %h %h %h\n%h %h %h %h\n%h %h %h %h", 
                 data_in[127:120], data_in[95:88], data_in[63:56], data_in[31:24],  // Linha 0
                 data_in[119:112], data_in[87:80], data_in[55:48], data_in[23:16],  // Linha 1
                 data_in[111:104], data_in[79:72], data_in[47:40], data_in[15:8],   // Linha 2
                 data_in[103:96],  data_in[71:64], data_in[39:32], data_in[7:0]);   // Linha 3

        $display("\nSaida (Esperado: Linha 1 deve ser 11 21 31 10):");
        $display("%h %h %h %h\n%h %h %h %h\n%h %h %h %h\n%h %h %h %h", 
                 data_out[127:120], data_out[95:88], data_out[63:56], data_out[31:24], 
                 data_out[119:112], data_out[87:80], data_out[55:48], data_out[23:16], 
                 data_out[111:104], data_out[79:72], data_out[47:40], data_out[15:8], 
                 data_out[103:96],  data_out[71:64], data_out[39:32], data_out[7:0]);

        #10 $finish;
    end
endmodule