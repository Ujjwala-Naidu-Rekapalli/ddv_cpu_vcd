# --- Setup (same as before) ---
puts ""
puts "# UVM include dir"
set UVM_INC /usr/local/mentor/modelsim10.4/verilog_src/uvm-1.1d/src
puts $UVM_INC

vlib work
vmap work work

# --- Compile ---
puts "\n# Compile"
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

# --- Simulate headless ---
puts "\n# Simulate in console mode"
vsim -c tb_uvm_cpu +HEX=mem/instr_mem.hex +UVM_VERBOSITY=UVM_MEDIUM

# --- VCD: pick signals that actually exist ---
puts "\n# VCD selection"
vcd file logs/uvm_cpu.vcd

# 1) Everything from the monitor interface (simple & safe)
#    This avoids the [] quoting issue entirely.
vcd add -r /tb_uvm_cpu/mon_if/*

# 2) A few DUT signals you listed in your header dump
#    NOTE: wrap names with [] in braces { } to avoid TCL command substitution
vcd add {/tb_uvm_cpu/DUT/EX_MEM/alu_y}
vcd add {/tb_uvm_cpu/DUT/EX_MEM/clk}
vcd add {/tb_uvm_cpu/DUT/EX_MEM/rst}
vcd add {/tb_uvm_cpu/DUT/FWD/forwardA}
vcd add {/tb_uvm_cpu/DUT/FWD/forwardB}

# --- Run and finish ---
puts "\n# Run and finish"
run 2us
vcd flush
quit -f

