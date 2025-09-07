# --- scripts/run_uvm_cpu_vcd.do ---

# UVM include dir
set UVM_INC /usr/local/mentor/modelsim10.4/verilog_src/uvm-1.1d/src
puts $UVM_INC

# Fresh work lib
if {[file exists work]} { vdel -all ; }
vlib work
vmap work work

# Compile everything
vlog -sv +acc +incdir+$UVM_INC \
  tb/cpu_mon_if.sv \
  tb/uvm/cpu_pkg.sv \
  tb/tb_uvm_cpu.sv \
  rtl/forward_unit.sv \
  rtl/hazard_unit.sv \
  rtl/cpu/alu.sv \
  rtl/cpu/regfile.sv \
  rtl/cpu/imm_gen.sv \
  rtl/cpu/control.sv \
  rtl/cpu/alu_control.sv \
  rtl/cpu/branch_unit.sv \
  rtl/cpu/if_id.sv \
  rtl/cpu/id_ex.sv \
  rtl/cpu/ex_mem.sv \
  rtl/cpu/mem_wb.sv \
  rtl/cpu/instr_mem.sv \
  rtl/cpu/data_mem.sv \
  rtl/riscv_cpu.sv

# Simulate headless
vsim -c tb_uvm_cpu "+HEX=mem/instr_mem.hex" "+UVM_VERBOSITY=UVM_MEDIUM"

# VCD out file
vcd file logs/uvm_cpu.vcd

# Monitor interface signals
vcd add -r /tb_uvm_cpu/mon_if/*

# (optional) a few DUT internals for extended plots
vcd add -r /tb_uvm_cpu/DUT/EX_MEM/*
vcd add -r /tb_uvm_cpu/DUT/FWD/*
vcd add -r /tb_uvm_cpu/DUT/IMEM/*

# Run and finish
run 2us
vcd flush
quit -f

