// tb/tb_uvm_cpu.sv
`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import cpu_pkg::*;

module tb_uvm_cpu;

  // ------------------------------------------------------------
  // Clock & reset
  // ------------------------------------------------------------
  logic clk;
  logic rst;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz
  end

  initial begin
    rst = 1'b1;
    #20 rst = 1'b0;
  end

  // ------------------------------------------------------------
  // Monitor interface instance (driven by DUT)
  // ------------------------------------------------------------
  cpu_mon_if mon_if(clk);

  // ------------------------------------------------------------
  // DUT
  //   Make sure riscv_cpu has these monitor ports:
  //     mon_pc, mon_branch_taken, mon_stall, mon_forwardA, mon_forwardB
  // ------------------------------------------------------------
  riscv_cpu DUT (
    .clk             (clk),
    .rst             (rst),

    // Commit monitor outputs (unused here)
    .commit_valid    (),
    .commit_rd       (),
    .commit_wdata    (),

    // Hook DUT monitor ports into our interface
    .mon_pc          (mon_if.pc),
    .mon_branch_taken(mon_if.branch_taken),
    .mon_stall       (mon_if.stall),
    .mon_forwardA    (mon_if.forwardA),
    .mon_forwardB    (mon_if.forwardB)
  );

  // ------------------------------------------------------------
  // UVM bring-up
  // ------------------------------------------------------------
  initial begin
    // Pass the virtual interface to the env/monitor
    uvm_config_db#(virtual cpu_mon_if)::set(null, "uvm_test_top.*", "vif", mon_if);

    // IMPORTANT: Start UVM at time 0 (no pre-run delays)
    run_test("cpu_smoke_test");
  end

endmodule

