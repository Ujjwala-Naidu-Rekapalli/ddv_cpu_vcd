module imm_gen(
    input  logic [31:0] instr,
    output logic [31:0] imm_i,
    output logic [31:0] imm_s,
    output logic [31:0] imm_b
);
    // I-type (ADDI/LW)
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    // S-type (SW)
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    // B-type (BEQ)
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
endmodule

