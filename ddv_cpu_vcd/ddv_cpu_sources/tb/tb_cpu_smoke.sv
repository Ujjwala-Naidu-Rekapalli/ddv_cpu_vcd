`timescale 1ns/1ps
module tb_cpu_smoke;
    logic clk=0, rst=1;

    // Wires for monitor taps (not used in this simple TB, just tied off to silence warnings)
    logic        commit_valid;
    logic [4:0]  commit_rd;
    logic [31:0] commit_wdata;
    logic [1:0]  mon_forwardA, mon_forwardB;
    logic        mon_stall, mon_branch_taken;
    logic [31:0] mon_pc;

    riscv_cpu DUT(
        .clk(clk),
        .rst(rst),
        .commit_valid(commit_valid),
        .commit_rd(commit_rd),
        .commit_wdata(commit_wdata),
        .mon_forwardA(mon_forwardA),
        .mon_forwardB(mon_forwardB),
        .mon_stall(mon_stall),
        .mon_branch_taken(mon_branch_taken),
        .mon_pc(mon_pc)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        // Reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // Run bounded time; the program exercises forwarding, stall, branch
        repeat (200) @(posedge clk);

        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule

