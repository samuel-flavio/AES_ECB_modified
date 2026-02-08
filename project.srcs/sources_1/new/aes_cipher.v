module aes_cipher(
    input clk,
    input reset,
    input start,
    input [127:0] plaintext,
    input [127:0] initial_key,
    output reg [127:0] ciphertext,
    output reg busy,
    output reg done
);

    // --- ESTADOS DA FSM ---
    localparam IDLE            = 3'b000;
    localparam INITIAL_ROUND   = 3'b001;
    localparam EXPAND_KEY      = 3'b010;
    localparam WAIT_SBOX       = 3'b011;
    localparam CALCULATE_ROUND = 3'b100;
    localparam DONE            = 3'b101;

    reg [2:0] current_state, next_state;
    reg [3:0] round_count;
    reg [127:0] state_reg;
    reg [127:0] key_reg;

    // --- SINAIS DE INTERCONEXÃO ---
    wire [127:0] sb_out, sr_out, mc_out, ark_out;
    wire [127:0] next_key_out;
    wire key_ready;
    reg key_start;
    wire [127:0] ark_input_state;

    // --- INSTANCIAÇÕES DOS SEUS MÓDULOS ---
    
    // 1. Expansão de Chave
    key_expansion key_unit (
        .clk(clk), .reset(reset), .start(key_start),
        .round(round_count), .key_in(key_reg),
        .key_out(next_key_out), .ready(key_ready)
    );

    // 2. Processamento do Estado (Data Path)
    sub_bytes sb_unit (.clk(clk), .state_in(state_reg), .state_out(sb_out));
    shift_rows sr_unit (.data_in(sb_out), .data_out(sr_out));
    mix_columns mc_unit (.data_in(sr_out), .data_out(mc_out));
    
    // Mux para pular MixColumns na Rodada 10
    assign ark_input_state = (round_count == 4'd10) ? sr_out : mc_out;
    
    // 3. AddRoundKey
    add_round_key ark_unit (
        .state_in(ark_input_state), 
        .round_key(key_reg), 
        .state_out(ark_out)
    );

    // --- LÓGICA DE TRANSIÇÃO DE ESTADOS ---
    always @(posedge clk or posedge reset) begin
        if (reset) current_state <= IDLE;
        else       current_state <= next_state;
    end

    // --- LÓGICA COMBINACIONAL DA FSM ---
    always @(*) begin
        next_state = current_state;
        key_start = 0;
        case (current_state)
            IDLE:            if (start) next_state = INITIAL_ROUND;
            INITIAL_ROUND:   next_state = EXPAND_KEY;
            EXPAND_KEY:      begin
                                key_start = 1;
                                if (key_ready) next_state = WAIT_SBOX;
                             end
            WAIT_SBOX:       next_state = CALCULATE_ROUND;
            CALCULATE_ROUND: if (round_count == 4'd10) next_state = DONE;
                             else                     next_state = EXPAND_KEY;
            DONE:            next_state = IDLE;
        endcase
    end

    // --- LÓGICA DE CONTROLE E REGISTRADORES ---
    always @(posedge clk) begin
        if (reset) begin
            round_count <= 0;
            busy <= 0;
            done <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    done <= 0;
                    busy <= 0;
                end
                
                INITIAL_ROUND: begin
                    busy <= 1;
                    state_reg <= plaintext ^ initial_key; // Round 0
                    key_reg <= initial_key;
                    round_count <= 1;
                end

                EXPAND_KEY: begin
                    if (key_ready) key_reg <= next_key_out;
                end

                CALCULATE_ROUND: begin
                    state_reg <= ark_out;
                    if (round_count < 10) round_count <= round_count + 1;
                end

                DONE: begin
                    ciphertext <= state_reg;
                    done <= 1;
                    busy <= 0;
                end
            endcase
        end
    end

endmodule