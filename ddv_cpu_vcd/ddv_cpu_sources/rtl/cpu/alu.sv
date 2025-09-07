module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_ctrl,   // 0000:add, 0001:sub
    output logic [31:0] y,
    output logic        zero
);
    always_comb begin
        unique case (alu_ctrl)
            4'b0000: y = a + b;   // ADD/ADDI/LW/SW address calc
            4'b0001: y = a - b;   // SUB (for BEQ compare path)
            default: y = 32'h0;
        endcase
    end

    assign zero = (y == 32'h0);
endmodule

