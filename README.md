# DDV CPU VCD Project (archive)

## Contents
- `matlab/cpu_vcd_tools/` — MATLAB VCD parsing/plotting utilities.
 - `vcd/uvm_cpu.vcd` — sample VCD.
- `modelsim_logs/` — logs, WLF/VCD from ModelSim.
- `ddv_cpu_sources/` — RTL, TBs, .do scripts (copied from server).
- `run_uvm_cpu_vcd_targets.do` — capture script.

## Quick MATLAB usage
```matlab
addpath('~/Projects/ddv_cpu_vcd/matlab/cpu_vcd_tools');
vcd = fullfile('~/Projects/ddv_cpu_vcd','vcd','uvm_cpu.vcd');
vcd_quicklook(vcd);             % scalar + int’ized buses quick plot
plot_pc_from_vcd_standalone(vcd); % PC plot if present


### 3) Create a zip to submit/share
```bash
cd ~/Projects
zip -r ddv_cpu_vcd_$(date +%Y%m%d).zip ddv_cpu_vcd


