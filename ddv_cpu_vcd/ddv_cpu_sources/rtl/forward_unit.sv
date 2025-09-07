// 2-bit mux select encoding:
// 00: use ID/EX register value
// 10: forward from EX/MEM stage
// 01: forward from MEM/WB stage
module forward_unit (
    input  logic        ex_mem_regwrite,
    input  logic [4:0]  ex_mem_rd,
    input  logic        mem_wb_regwrite,
    input  logic [4:0]  mem_wb_rd,
    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,
    output logic [1:0]  forwardA,
    output logic [1:0]  forwardB
);
    always_comb begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        // RS1 path
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
            forwardA = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
            forwardA = 2'b01;

        // RS2 path
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
            forwardB = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
            forwardB = 2'b01;
    end
endmodule

