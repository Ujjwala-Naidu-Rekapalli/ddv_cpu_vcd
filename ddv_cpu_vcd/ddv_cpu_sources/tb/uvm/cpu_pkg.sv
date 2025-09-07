// tb/uvm/cpu_pkg.sv
`ifndef CPU_PKG_SV
`define CPU_PKG_SV

package cpu_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Forward declaration of interface type (defined in tb/cpu_mon_if.sv)
  typedef virtual cpu_mon_if cpu_mon_if_v;

  // ------------------------------------------------------------
  // Monitor: samples the interface every clock and updates a covergroup
  // NOTE: We do NOT reference vif inside the covergroup (older tools can choke).
  //       Instead we snapshot signals into class fields and sample() the CG.
  // ------------------------------------------------------------
  class cpu_monitor extends uvm_component;
    `uvm_component_utils(cpu_monitor)

    // Virtual interface from TB
    cpu_mon_if_v vif;

    // Snapshot variables for coverage (decoupled from vif)
    bit          branch_taken_s;
    bit          stall_s;
    bit [1:0]    fwdA_s;
    bit [1:0]    fwdB_s;

    // Covergroup without a clocking event; we call cg.sample() manually.
    covergroup cg;
      coverpoint branch_taken_s;
      coverpoint stall_s;

      coverpoint fwdA_s {
        bins none = {2'b00};
        bins EX   = {2'b10};
        bins MEM  = {2'b01};
      }

      coverpoint fwdB_s {
        bins none = {2'b00};
        bins EX   = {2'b10};
        bins MEM  = {2'b01};
      }

      cross stall_s, branch_taken_s;
    endgroup

    function new(string name = "cpu_monitor", uvm_component parent = null);
      super.new(name, parent);
      cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(cpu_mon_if_v)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "cpu_monitor: virtual interface 'vif' not found in config DB")
      end
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      forever begin
        @(posedge vif.clk);
        // snapshot, then sample coverage
        branch_taken_s = vif.branch_taken;
        stall_s        = vif.stall;
        fwdA_s         = vif.forwardA;
        fwdB_s         = vif.forwardB;
        cg.sample();
      end
      // (No drop here; test controls runtime/timeout.)
      // phase.drop_objection(this);
    endtask

  endclass : cpu_monitor

  // ------------------------------------------------------------
  // Simple environment with just the monitor
  // ------------------------------------------------------------
  class cpu_env extends uvm_env;
    `uvm_component_utils(cpu_env)

    cpu_monitor mon;

    function new(string name = "cpu_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = cpu_monitor::type_id::create("mon", this);
    endfunction

  endclass : cpu_env

  // ------------------------------------------------------------
  // Smoke test: run a bounded amount of time, then finish.
  // ------------------------------------------------------------
  class cpu_smoke_test extends uvm_test;
    `uvm_component_utils(cpu_smoke_test)

    cpu_env m_env;

    function new(string name = "cpu_smoke_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_env = cpu_env::type_id::create("m_env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // Run long enough for your CPU smoke to execute (adjust if needed)
      #2000ns;
      phase.drop_objection(this);
    endtask

  endclass : cpu_smoke_test

endpackage : cpu_pkg

`endif // CPU_PKG_SV

