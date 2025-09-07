module regfile(
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] rf[31:0];

    // x0 hardwired to 0
    always_ff @(posedge clk) begin
        if (we && rd != 5'd0) rf[rd] <= wd;
        rf[0] <= 32'h0;
    end

    assign rd1 = (rs1!=0) ? rf[rs1] : 32'h0;
    assign rd2 = (rs2!=0) ? rf[rs2] : 32'h0;
endmodule

