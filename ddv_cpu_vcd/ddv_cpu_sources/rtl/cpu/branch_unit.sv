module branch_unit(
    input  logic       branch,
    input  logic [2:0] funct3,  // only BEQ (000) used here
    input  logic       zero,
    output logic       take
);
    always_comb begin
        take = 1'b0;
        if (branch) begin
            if (funct3==3'b000) take = zero; // BEQ
        end
    end
endmodule

