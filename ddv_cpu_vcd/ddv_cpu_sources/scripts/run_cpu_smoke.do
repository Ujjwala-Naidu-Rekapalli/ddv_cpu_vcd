if {[file exists work]} { vdel -all }
vlib work
vmap work work

vlog -sv rtl/forward_unit.sv \
        rtl/hazard_unit.sv \
        rtl/cpu/alu.sv rtl/cpu/regfile.sv rtl/cpu/imm_gen.sv rtl/cpu/control.sv rtl/cpu/alu_control.sv rtl/cpu/branch_unit.sv \
        rtl/cpu/if_id.sv rtl/cpu/id_ex.sv rtl/cpu/ex_mem.sv rtl/cpu/mem_wb.sv \
        rtl/cpu/instr_mem.sv rtl/cpu/data_mem.sv \
        rtl/riscv_cpu.sv tb/tb_cpu_smoke.sv

vsim -c tb_cpu_smoke
vcd file logs/cpu_smoke.vcd
vcd add -r /*
run -all
quit -f

