module control(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic       branch,
    output logic       memRead,
    output logic       memWrite,
    output logic       regWrite,
    output logic       aluSrc,     // 1=imm, 0=reg
    output logic [1:0] aluOp       // 00:add, 01:sub (branch compare)
);
    always_comb begin
        branch=0; memRead=0; memWrite=0; regWrite=0; aluSrc=0; aluOp=2'b00;
        unique case (opcode)
            7'b0110011: begin // R-type (ADD)
                regWrite=1; aluSrc=0; aluOp=2'b00;
            end
            7'b0010011: begin // I-type (ADDI)
                regWrite=1; aluSrc=1; aluOp=2'b00;
            end
            7'b0000011: begin // LOAD (LW)
                memRead=1; regWrite=1; aluSrc=1; aluOp=2'b00;
            end
            7'b0100011: begin // STORE (SW)
                memWrite=1; aluSrc=1; aluOp=2'b00;
            end
            7'b1100011: begin // BRANCH (BEQ)
                branch=1; aluSrc=0; aluOp=2'b01; // use SUB for compare
            end
            default: ;
        endcase
    end
endmodule

