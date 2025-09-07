module mem_wb(
    input  logic        clk, rst,
    input  logic [31:0] mem_data_in, alu_y_in,
    input  logic [4:0]  rd_in,
    input  logic        regWrite_in,
    input  logic        memRead_in,
    output logic [31:0] mem_data, alu_y,
    output logic [4:0]  rd,
    output logic        regWrite,
    output logic        memRead
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data<=0; alu_y<=0; rd<=0; regWrite<=0; memRead<=0;
        end else begin
            mem_data<=mem_data_in; alu_y<=alu_y_in; rd<=rd_in; regWrite<=regWrite_in; memRead<=memRead_in;
        end
    end
endmodule

