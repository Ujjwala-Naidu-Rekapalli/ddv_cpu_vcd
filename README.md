# Pipelined RISC-V CPU with Hazards/Forwarding + UVM Testbench + MATLAB VCD Analysis

This project implements a **5-stage RISC-V CPU** (IF → ID → EX → MEM → WB) with:
- **Hazard detection unit** (load-use stall handling)
- **Forwarding unit** (EX/MEM bypassing to avoid stalls)
- **UVM testbench** (SystemVerilog, ModelSim/Questa)
- **MATLAB post-processing** to parse **VCD waveforms** and plot CPU activity

End-to-end flow: RTL → UVM simulation → VCD dump → MATLAB visualization

---

## Repository Layout
rtl/ # CPU RTL: ALU, control, forwarding, hazard, pipeline regs
tb/ # UVM testbench: interfaces, cpu_pkg, test sequences
scripts/ # ModelSim .do scripts (run_uvm_cpu.do, run_uvm_cpu_vcd.do, etc.)
mem/ # Sample instr_mem.hex for smoke tests
matlab/ # VCD parsing + plotting utilities
logs/ # Contains one small demo VCD (uvm_cpu_demo.vcd)
docs/ # Block diagrams and MATLAB screenshots

---

## Quick Start

### A) Run UVM Test in ModelSim/Questa
From the repo root:
```tcl
vsim -c -do scripts/run_uvm_cpu_vcd.do

## MATLAB quick look

```matlab
restoredefaultpath; rehash toolboxcache;
cd('~/Projects/ddv_cpu_vcd_repo');
addpath('matlab/cpu_vcd_tools');
vcd = fullfile(pwd,'logs','uvm_cpu_demo.vcd');
plot_cpu_quick(vcd);

