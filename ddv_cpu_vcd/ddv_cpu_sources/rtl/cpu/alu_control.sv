module alu_control(
    input  logic [1:0] aluOp,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_ctrl
);
    always_comb begin
        alu_ctrl = 4'b0000;          // default ADD
        unique case (aluOp)
            2'b00: alu_ctrl = 4'b0000; // add
            2'b01: alu_ctrl = 4'b0001; // sub (for BEQ)
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule

