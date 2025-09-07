# ==== Compile ====
set UVM_INC /usr/local/mentor/modelsim10.4/verilog_src/uvm-1.1d/src

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

# ==== Simulate (no nested -do) ====
vsim -c tb_uvm_cpu +HEX=mem/instr_mem.hex +UVM_VERBOSITY=UVM_MEDIUM
run 2us
quit -f

