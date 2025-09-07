function plot_cpu_dashboard_v2(vcd_path)
% plot_cpu_dashboard_v2  — robust, self-contained VCD plotting script.
% It auto-resolves signal names from your VCD header and plots what it finds.
%
% Usage:
%   plot_cpu_dashboard_v2;                      % uses ~/Downloads/uvm_cpu.vcd
%   plot_cpu_dashboard_v2('/path/to/uvm_cpu.vcd');

    % --- 0) Pick a default VCD if none was supplied
    if nargin < 1 || isempty(vcd_path)
        vcd_path = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');
    end
    assert(exist(vcd_path,'file')==2, 'VCD not found at: %s', vcd_path);

    % --- 1) Read the header variable names (as strings)
    vars = vcd_list_vars(vcd_path);
    vars = vars(:);
    % Some VCD writers put a space before bracket; keep both styles handy
    varsNoSp = regexprep(vars,'\s+\[','[');

    % Helper to find first variable whose *tail/suffix* matches a pattern.
    % We match on the end so hierarchy differences still work.
    function hit = find_by_suffix(candidates)
        hit = '';
        if ischar(candidates), candidates = {candidates}; end
        for c = candidates
            pat = regexptranslate('escape', c{1});
            % Allow either space or no-space before brackets at the very end
            pat = strrep(pat, '\[', '\s*\[');
            tail = ['(' pat ')$'];
            idx = find(~cellfun('isempty', regexp(vars, tail)), 1, 'first');
            if isempty(idx)
                idx = find(~cellfun('isempty', regexp(varsNoSp, tail)), 1, 'first');
            end
            if ~isempty(idx)
                hit = vars{idx};
                return;
            end
        end
    end

    % --- 2) Propose common names, then resolve to what your VCD actually has
    clk         = find_by_suffix('/tb_uvm_cpu/mon_if/clk');
    if isempty(clk),    clk    = find_by_suffix('/tb_uvm_cpu/DUT/EX_MEM/clk'); end
    if isempty(clk),    clk    = find_by_suffix('/clk'); end

    rst         = find_by_suffix('/tb_uvm_cpu/mon_if/rst');
    if isempty(rst),    rst    = find_by_suffix('/tb_uvm_cpu/DUT/EX_MEM/rst'); end
    if isempty(rst),    rst    = find_by_suffix('/rst'); end

    branch      = find_by_suffix('/tb_uvm_cpu/mon_if/branch_taken');
    if isempty(branch), branch = find_by_suffix('/branch_taken'); end

    stall       = find_by_suffix('/tb_uvm_cpu/mon_if/stall');
    if isempty(stall),  stall  = find_by_suffix('/stall'); end

    forwardA    = find_by_suffix('/tb_uvm_cpu/mon_if/forwardA [1:0]');
    if isempty(forwardA),forwardA = find_by_suffix('/tb_uvm_cpu/DUT/FWD/forwardA [1:0]'); end
    if isempty(forwardA),forwardA = find_by_suffix('forwardA [1:0]'); end

    forwardB    = find_by_suffix('/tb_uvm_cpu/mon_if/forwardB [1:0]');
    if isempty(forwardB),forwardB = find_by_suffix('/tb_uvm_cpu/DUT/FWD/forwardB [1:0]'); end
    if isempty(forwardB),forwardB = find_by_suffix('forwardB [1:0]'); end

    pc_bus      = find_by_suffix('/tb_uvm_cpu/mon_if/pc [31:0]');
    if isempty(pc_bus), pc_bus = find_by_suffix('/pc [31:0]'); end
    % A useful datapath signal present in your file:
    alu_y_bus   = find_by_suffix('/tb_uvm_cpu/DUT/EX_MEM/alu_y [31:0]');

    % --- 3) Print what we resolved (the missing dispKV caused your earlier error)
    fprintf('\n--- Resolved names (based on what exists in your VCD) ---\n');
    dispKV('clk',         clk);
    dispKV('rst',         rst);
    dispKV('branch',      branch);
    dispKV('stall',       stall);
    dispKV('forwardA',    forwardA);
    dispKV('forwardB',    forwardB);
    dispKV('pc_bus',      pc_bus);
    dispKV('alu_y_bus',   alu_y_bus);

    % Collect wanted signals (try both spacing styles for brackets)
    wanted = {};
    for nm = {clk,rst,branch,stall,forwardA,forwardB,pc_bus,alu_y_bus}
        if ~isempty(nm{1})
            wanted{end+1} = nm{1}; %#ok<AGROW>
        end
    end
    wanted_nos = regexprep(wanted,'\s+\[','[');

    % --- 4) Parse what we can (be tolerant: some may fail / be absent)
    sigs = try_parse(vcd_path, wanted);
    if isempty(sigs)
        sigs = try_parse(vcd_path, wanted_nos);
    end
    if isempty(sigs)
        error('None of the requested signals could be parsed. Check names above.');
    end

    % Put parsed signals into a map by *suffix* for easy lookup
    S = containers.Map();
    for i = 1:numel(sigs)
        S( strip_suffix(sigs(i).name) ) = sigs(i);
    end

    % Helper to pull a signal by any of several suffixes
    function s = getS(varargin)
        s = [];
        for k = 1:nargin
            key = varargin{k};
            if S.isKey(key), s = S(key); return; end
        end
    end

    % --- 5) Build the dashboard (plot only what we have)
    figure('Name','CPU Dashboard (VCD)','Color','w','NumberTitle','off');
    tiledlayout(3,2,'Padding','compact','TileSpacing','compact');

    % 5a) Clock
    nexttile;
    sig = getS('/tb_uvm_cpu/mon_if/clk','/tb_uvm_cpu/DUT/EX_MEM/clk','/clk');
    plot_scalar(sig,'Clock');

    % 5b) Reset
    nexttile;
    sig = getS('/tb_uvm_cpu/mon_if/rst','/tb_uvm_cpu/DUT/EX_MEM/rst','/rst');
    plot_scalar(sig,'Reset');

    % 5c) Branch/Stall
    nexttile;
    hold on; grid on;
    sigB = getS('/tb_uvm_cpu/mon_if/branch_taken','/branch_taken');
    sigS = getS('/tb_uvm_cpu/mon_if/stall','/stall');
    plotted = false;
    if ~isempty(sigB), stairs_tv(sigB); plotted=true; end
    if ~isempty(sigS), stairs_tv(sigS); plotted=true; end
    if ~plotted, title('Branch/Stall (not found)'); else, legend_found(sigB,'branch',sigS,'stall'); title('Branch & Stall'); end
    xlabel('time');

    % 5d) Forwarding (as 2-bit buses)
    nexttile;
    hold on; grid on;
    sigFA = getS('/tb_uvm_cpu/mon_if/forwardA [1:0]','/tb_uvm_cpu/DUT/FWD/forwardA [1:0]','/forwardA [1:0]');
    sigFB = getS('/tb_uvm_cpu/mon_if/forwardB [1:0]','/tb_uvm_cpu/DUT/FWD/forwardB [1:0]','/forwardB [1:0]');
    plotted=false;
    if ~isempty(sigFA), stairs_tv(sigFA); plotted=true; end
    if ~isempty(sigFB), stairs_tv(sigFB); plotted=true; end
    if ~plotted, title('Forwarding (not found)');
    else, legend_found(sigFA,'forwardA',sigFB,'forwardB'); title('Forwarding (2-bit)'); end
    xlabel('time');

    % 5e) PC (as 32-bit bus, show as decimal if available)
    nexttile;
    sigPC = getS('/tb_uvm_cpu/mon_if/pc [31:0]','/pc [31:0]');
    if isempty(sigPC)
        title('PC [31:0] (not found)'); axis off;
    else
        plot_bus_as_decimal(sigPC,'PC [31:0]');
    end

    % 5f) ALU Y (as 32-bit bus)
    nexttile;
    sigALU = getS('/tb_uvm_cpu/DUT/EX_MEM/alu_y [31:0]');
    if isempty(sigALU)
        title('EX_MEM/alu_y [31:0] (not found)'); axis off;
    else
        plot_bus_as_decimal(sigALU,'EX\_MEM/alu\_y [31:0]');
    end

    sgtitle('CPU Dashboard (from VCD)','FontWeight','bold');

    % ======================= helpers =========================

    function out = strip_suffix(name)
        % returns the canonical suffix we’ll use as a key
        out = regexprep(name,'^\s*','');
        out = regexprep(out,'\s+$','');
        % keep hierarchy; we key on full path to avoid collisions
    end

    function sigs = try_parse(vcd_file, wantedList)
        sigs = [];
        if isempty(wantedList), return; end
        try
            sigs = parse_vcd_signals(vcd_file, wantedList);
        catch
            % swallow; return empty; caller will try variants
            sigs = [];
        end
    end

    function dispKV(k,v)
        if isempty(v), v = '(none)'; end
        fprintf('%12s: %s\n', k, v);
    end

    function plot_scalar(sig, ttl)
        if isempty(sig)
            title([ttl ' (not found)']); axis off; return;
        end
        hold on; grid on;
        stairs_tv(sig);
        title(ttl);
        xlabel('time'); ylabel('val');
    end

    function stairs_tv(sig)
        % Generic time/value stairs for scalar OR small-vector (already decoded)
        t = double(sig.time(:));
        v = double(sig.val(:));
        if isempty(t)
            % nothing toggled; draw a flat line if value known
            t = [0; 1];
            v = [0; 0];
        else
            % typical stairs needs one extra sample to hold last value
            t = [t; t(end)+1];
            v = [v; v(end)];
        end
        stairs(t, v, 'LineWidth', 1);
    end

    function plot_bus_as_decimal(sigBus, ttl)
        % If parser already decoded vector values, plot them as decimal.
        % Otherwise, try to decode from a binary/hex string in sigBus.val.
        hold on; grid on;
        t  = double(sigBus.time(:));
        vv = sigBus.val;
        % Try a few formats:
        if isnumeric(vv)
            valDec = double(vv);
        elseif iscell(vv)
            % cellstr of binary/hex? try to interpret
            valDec = nan(numel(vv),1);
            for ii=1:numel(vv)
                s = strtrim(vv{ii});
                if startsWith(s,'b'), valDec(ii) = bin2dec(s(2:end)); %#ok<*ST2NM>
                elseif startsWith(s,'h'), valDec(ii) = hex2dec(s(2:end));
                elseif all(ismember(s,'01'))
                    valDec(ii) = bin2dec(s);
                else
                    % fall back: try numeric conversion
                    x = str2double(s);
                    if ~isnan(x), valDec(ii) = x; end
                end
            end
            % replace any NaNs with previous value
            for ii=2:numel(valDec)
                if isnan(valDec(ii)), valDec(ii)=valDec(ii-1); end
            end
            if isnan(valDec(1)), valDec(1)=0; end
        else
            % unknown format; just don’t plot
            title([ttl ' (parsed, but unknown val format)']);
            xlabel('time');
            return;
        end

        if isempty(t)
            t = [0;1];
            valDec = [0;0];
        else
            t = [t; t(end)+1];
            valDec = [valDec(:); valDec(end)];
        end
        stairs(t, valDec, 'LineWidth', 1);
        title(ttl);
        xlabel('time'); ylabel('decimal');
    end
end
