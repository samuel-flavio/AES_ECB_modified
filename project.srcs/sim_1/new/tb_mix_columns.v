`timescale 1ns / 1ps

module tb_mix_columns();

    reg  [127:0] data_in;
    wire [127:0] data_out;
    reg  [127:0] expected_out;

    // Instanciação do módulo MixColumns que criamos
    mix_columns dut (
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        // 1. Configura os dados baseados na figura do Stallings
        // Entrada (Matriz à esquerda)
        data_in = 128'h876E46A6_F24CE78C_4D904AD8_97ECC395;
        
        // Saída Esperada (Matriz à direita)
        expected_out = 128'h473794ED_40D4E4A5_A3703AA6_4C9F42BC;

        // 2. Aguarda um tempo para a lógica combinacional estabilizar
        #10;

        // 3. Exibição dos resultados no console (Tcl Console do Vivado)
        $display("--- Teste MixColumns (Referência: Stallings) ---");
        $display("Entrada:  %h", data_in);
        $display("Saída:    %h", data_out);
        $display("Esperado: %h", expected_out);

        // 4. Verificação automática
        if (data_out === expected_out) begin
            $display("\nSUCESSO: A saída corresponde exatamente à matriz do livro!");
        end else begin
            $display("\nERRO: A saída divergiu do esperado. Verifique a função xtime ou a ordem dos bytes.");
        end

        #20 $finish;
    end

endmodule