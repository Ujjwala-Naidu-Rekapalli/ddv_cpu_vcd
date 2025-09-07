% plot_cpu_quick.m
% Quick, no-drama parse/plot for the signals that DO exist in your VCD.

addpath('~/Documents/MATLAB/cpu_vcd_tools');

vcd = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');

% From your header dump (these paths exist there)
wanted = { ...
  '/tb_uvm_cpu/DUT/EX_MEM/clk', ...
  '/tb_uvm_cpu/DUT/EX_MEM/rst', ...
  '/tb_uvm_cpu/DUT/FWD/forwardA [1:0]', ...
  '/tb_uvm_cpu/DUT/FWD/forwardB [1:0]', ...
  '/tb_uvm_cpu/DUT/EX_MEM/alu_y [31:0]' ...
};

% Normalize both "space-before-[" and "no-space" automatically.
sigs = vcd_read_signals(vcd, wanted);

% Filter out empties (if any weren’t toggled)
nonempty = arrayfun(@(s) ~isempty(s.time), sigs);
sigs = sigs(nonempty);

if isempty(sigs)
    fprintf(2,'Nothing parsed. Double-check that the VCD has value changes.\n');
    return
end

% Plot: scalars as 0/1, vectors as integer stairs.
figure('Name','CPU quick look'); hold on; grid on;
leg = {};
for i = 1:numel(sigs)
    t = double(sigs(i).time);
    v = sigs(i).val;
    if isa(v,'uint8') % came from scalar 0/1/X
        % Keep only 0/1; map X/Z(255) -> previous value (or 0)
        vv = double(v);
        vv(vv==255) = nan;                % show gaps for X/Z
        if all(ismember(unique(v(~isnan(vv))), [0 1]))
            last = 0;
            for k = 1:numel(vv)
                if isnan(vv(k)), vv(k) = last; else, last = vv(k); end
            end
            stairs([t; t(end)+1],[vv; vv(end)]);
            leg{end+1} = sigs(i).name; %#ok<SAGROW>
        end
    else
        % vectors stored as uint64 (integer value of the bus)
        vv = double(v);
        stairs([t; t(end)+1],[vv; vv(end)]);
        leg{end+1} = sigs(i).name;
    end
end
xlabel('time'); ylabel('value');
title('Quick CPU signals (scalar + integerized buses)');
legend(leg,'Interpreter','none','Location','best');
