module sub_bytes (
    input              clk,
    input      [127:0] state_in,
    output     [127:0] state_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_loop
            sbox sb_inst (
                .clk  (clk),
                .addr (state_in[i*8 +: 8]), // Seleciona o byte i (i*8 até i*8+7)
                .data (state_out[i*8 +: 8])
            );
        end
    endgenerate

endmodule