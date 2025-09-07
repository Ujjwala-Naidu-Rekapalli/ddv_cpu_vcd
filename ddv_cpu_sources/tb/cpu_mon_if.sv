// tb/cpu_mon_if.sv
interface cpu_mon_if(input logic clk);
  logic [31:0] pc;
  logic        branch_taken;
  logic        stall;
  logic [1:0]  forwardA;
  logic [1:0]  forwardB;
endinterface

