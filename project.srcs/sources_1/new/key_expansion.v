module key_expansion(
    input clk,
    input reset,
    input start,              // Pulso para iniciar a expansão para a próxima rodada
    input [3:0] round,        // Rodada atual (1 a 10)
    input [127:0] key_in,     // Chave da rodada anterior (w0, w1, w2, w3)
    output reg [127:0] key_out, // Chave da nova rodada (w4, w5, w6, w7)
    output reg ready          // Sinaliza que a nova chave está estável
);

    // Estados da FSM
    localparam IDLE      = 2'b00;
    localparam WAIT_VLD  = 2'b01; // Aguarda estabilidade da função temp
    localparam CALCULATE = 2'b10;
    
    reg [1:0] state;
    wire [7:0] rcon_val;
    wire [31:0] g_temp;       // Saída do módulo key_transformation_logic
    wire g_vld;               // flag de validação vinda de key_transformation_logic
    reg g_en;                 // Enable para o key_transformation_logic

    // Instancia o módulo Rcon (o que usa case)
    rcon_lookup rcon_inst (
        .round(round),
        .rcon(rcon_val)
    );

    // Instancia a lógica de transformação (RotWord + SubWord + Rcon XOR)
    // Note que passamos a última palavra da chave anterior (key_in[31:0])
    key_transformation_logic g_func_inst (
        // ENTRADAS
        .word_in(key_in[31:0]),
        .rcon(rcon_val),
        .clk(clk),
        .reset(reset),
        .en(g_en),
        // SAÍDAS
        .word_out(g_temp),              // Saída Processada
        .vld_out(g_vld)                 // Indica o término do cálculo
    );

    // Lógica da FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            key_out <= 128'h0;
            ready <= 0;
            g_en <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 0;
                    if (start) begin
                        g_en <= 1;
                        state <= WAIT_VLD;
                    end
                end

                WAIT_VLD: begin
                    if (g_vld) begin
                        g_en <= 0;
                        state <= CALCULATE;
                    end
                end

                CALCULATE: begin
                    // Agora aplicamos a cascata de XORs (conforme o diagrama)
                    // w4 = w0 ^ g(w3)
                    // w5 = w1 ^ w4
                    // w6 = w2 ^ w5
                    // w7 = w3 ^ w6
                    
                    // w4
                    key_out[127:96] <= key_in[127:96] ^ g_temp;
                    // w5
                    key_out[95:64]  <= key_in[95:64]  ^ (key_in[127:96] ^ g_temp);
                    // w6
                    key_out[63:32]  <= key_in[63:32]  ^ (key_in[95:64]  ^ (key_in[127:96] ^ g_temp));
                    // w7
                    key_out[31:0]   <= key_in[31:0]   ^ (key_in[63:32]  ^ (key_in[95:64] ^ (key_in[127:96] ^ g_temp)));
                    
                    ready <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule