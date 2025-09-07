module id_ex(
    input  logic        clk, rst, flush,
    input  logic [31:0] pc_in, rs1_val_in, rs2_val_in, imm_i_in, imm_s_in,
    input  logic [4:0]  rs1_in, rs2_in, rd_in,
    input  logic [2:0]  funct3_in,
    input  logic [6:0]  funct7_in,
    input  logic        branch_in, memRead_in, memWrite_in, regWrite_in, aluSrc_in,
    input  logic [1:0]  aluOp_in,
    output logic [31:0] pc, rs1_val, rs2_val, imm_i, imm_s,
    output logic [4:0]  rs1, rs2, rd,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,
    output logic        branch, memRead, memWrite, regWrite, aluSrc,
    output logic [1:0]  aluOp
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc<=0; rs1_val<=0; rs2_val<=0; imm_i<=0; imm_s<=0; rs1<=0; rs2<=0; rd<=0;
            funct3<=0; funct7<=0; branch<=0; memRead<=0; memWrite<=0; regWrite<=0; aluSrc<=0; aluOp<=0;
        end else begin
            pc<=pc_in; rs1_val<=rs1_val_in; rs2_val<=rs2_val_in; imm_i<=imm_i_in; imm_s<=imm_s_in;
            rs1<=rs1_in; rs2<=rs2_in; rd<=rd_in; funct3<=funct3_in; funct7<=funct7_in;
            branch<=branch_in; memRead<=memRead_in; memWrite<=memWrite_in; regWrite<=regWrite_in; aluSrc<=aluSrc_in; aluOp<=aluOp_in;
        end
    end
endmodule

