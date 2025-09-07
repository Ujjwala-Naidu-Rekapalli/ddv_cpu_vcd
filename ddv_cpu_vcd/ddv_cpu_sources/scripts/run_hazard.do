if {[file exists work]} { vdel -all }
vlib work
vmap work work

vlog -sv rtl/hazard_unit.sv tb/tb_hazard_unit.sv

vsim -c tb_hazard_unit
vcd file logs/hazard.vcd
vcd add -r /*
run -all
quit -f
