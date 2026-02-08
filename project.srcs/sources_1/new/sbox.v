module sbox (
    input            clk,    // Clock é essencial para BRAM
    input      [7:0] addr,   // Endereço (byte de entrada do State)
    output reg [7:0] data    // Saída registrada (byte substituído)
);

    // Declaração da memória (256x8)
    (* rom_style = "block" *) reg [7:0] rom [0:255];

    // Inicialização via arquivo .mem
    initial begin
        $readmemh("sbox_data.mem", rom);
    end

    // Leitura síncrona: O Vivado mapeia isso automaticamente para BRAM
    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule