module ex_mem(
    input  logic        clk, rst,
    input  logic [31:0] alu_y_in, rs2_val_in,
    input  logic [4:0]  rd_in,
    input  logic [2:0]  funct3_in,
    input  logic        memRead_in, memWrite_in, regWrite_in,
    output logic [31:0] alu_y, rs2_val,
    output logic [4:0]  rd,
    output logic [2:0]  funct3,
    output logic        memRead, memWrite, regWrite
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_y<=0; rs2_val<=0; rd<=0; funct3<=0; memRead<=0; memWrite<=0; regWrite<=0;
        end else begin
            alu_y<=alu_y_in; rs2_val<=rs2_val_in; rd<=rd_in; funct3<=funct3_in;
            memRead<=memRead_in; memWrite<=memWrite_in; regWrite<=regWrite_in;
        end
    end
endmodule

