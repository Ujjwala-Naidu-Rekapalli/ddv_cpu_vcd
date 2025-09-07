# Clean work library
if {[file exists work]} { vdel -all }
vlib work
vmap work work

# Compile (SystemVerilog)
vlog -sv rtl/forward_unit.sv tb/tb_forward_unit.sv

# Launch sim, then issue commands sequentially (no nested -do)
vsim -c tb_forward_unit
vcd file logs/forward.vcd
vcd add -r /*
run -all
quit -f

