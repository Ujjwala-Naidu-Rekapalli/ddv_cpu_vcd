module data_mem(
    input  logic        clk,
    input  logic        memRead,
    input  logic        memWrite,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] ram[0:255];

    // Safe to keep an initial preload (separate process).
    // Old ModelSim objects to 'always_ff' + initial on same var. Use plain 'always' below.
    initial begin
        integer i;
        for (i=0; i<256; i=i+1) ram[i] = 32'h0;
        ram[3] = 32'd10; // so LW x4, 0(x3) reads 10 when x3=15
    end

    // Write port
    always @(posedge clk) begin
        if (memWrite) ram[addr[9:2]] <= wdata;
    end

    // Read port (combinational)
    assign rdata = memRead ? ram[addr[9:2]] : 32'hx;
endmodule

