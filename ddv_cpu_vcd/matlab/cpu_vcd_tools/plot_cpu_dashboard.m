function plot_cpu_dashboard(vcd_path)
% plot_cpu_dashboard  —  Visualize key CPU signals from a VCD.
%
% Usage:
%   >> addpath('~/Documents/MATLAB/cpu_vcd_tools');
%   >> plot_cpu_dashboard;                       % uses ~/Downloads/uvm_cpu.vcd
%   >> plot_cpu_dashboard('/full/path/to/uvm_cpu.vcd');
%
% Requires:
%   - parse_vcd_signals.m  (already on your path)
%   - vcd_list_vars.m      (we created earlier)

% 0) Locate VCD (default: ~/Downloads/uvm_cpu.vcd)
if nargin < 1 || isempty(vcd_path)
    vcd_path = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');
end
assert(exist(vcd_path,'file')==2, 'VCD not found: %s', vcd_path);

% 1) Read the list of signal names as they appear in the header
allhdr = vcd_list_vars(vcd_path);
allhdr = string(allhdr(:));              % normalize to string array
allhdr_nos = regexprep(allhdr,'\s+\[','['); % no-space variant for matching

% 2) Build alias tables (flat + hierarchical possibilities)
aliases.clk       = [ ...
    "clk","/clk",".clk", ...
    "/tb_uvm_cpu/mon_if/clk","tb_uvm_cpu.mon_if.clk","mon_if.clk" ...
];
aliases.branch    = [ ...
    "branch_taken","/branch_taken",".branch_taken", ...
    "/tb_uvm_cpu/mon_if/branch_taken","tb_uvm_cpu.mon_if.branch_taken","mon_if.branch_taken" ...
];
aliases.stall     = [ ...
    "stall","/stall",".stall", ...
    "/tb_uvm_cpu/mon_if/stall","tb_uvm_cpu.mon_if.stall","mon_if.stall" ...
];
aliases.fwdA_bus  = [ ...
    "forwardA [1:0]","forwardA[1:0]","/forwardA [1:0]","/forwardA[1:0]", ...
    "/tb_uvm_cpu/mon_if/forwardA [1:0]","/tb_uvm_cpu/mon_if/forwardA[1:0]", ...
    "tb_uvm_cpu.mon_if.forwardA [1:0]","tb_uvm_cpu.mon_if.forwardA[1:0]" ...
];
aliases.fwdB_bus  = [ ...
    "forwardB [1:0]","forwardB[1:0]","/forwardB [1:0]","/forwardB[1:0]", ...
    "/tb_uvm_cpu/mon_if/forwardB [1:0]","/tb_uvm_cpu/mon_if/forwardB[1:0]", ...
    "tb_uvm_cpu.mon_if.forwardB [1:0]","tb_uvm_cpu.mon_if.forwardB[1:0]" ...
];
aliases.fwdA_bits = [ ...
    "forwardA [1]","forwardA[1]","/forwardA [1]","/forwardA[1]", ...
    "/tb_uvm_cpu/mon_if/forwardA [1]","/tb_uvm_cpu/mon_if/forwardA[1]", ...
    "forwardA [0]","forwardA[0]","/forwardA [0]","/forwardA[0]", ...
    "/tb_uvm_cpu/mon_if/forwardA [0]","/tb_uvm_cpu/mon_if/forwardA[0]" ...
];
aliases.fwdB_bits = [ ...
    "forwardB [1]","forwardB[1]","/forwardB [1]","/forwardB[1]", ...
    "/tb_uvm_cpu/mon_if/forwardB [1]","/tb_uvm_cpu/mon_if/forwardB[1]", ...
    "forwardB [0]","forwardB[0]","/forwardB [0]","/forwardB[0]", ...
    "/tb_uvm_cpu/mon_if/forwardB [0]","/tb_uvm_cpu/mon_if/forwardB[0]" ...
];
aliases.pc_bus    = [ ...
    "pc [31:0]","pc[31:0]","/pc [31:0]","/pc[31:0]", ...
    "/tb_uvm_cpu/mon_if/pc [31:0]","/tb_uvm_cpu/mon_if/pc[31:0]", ...
    "tb_uvm_cpu.mon_if.pc [31:0]","tb_uvm_cpu.mon_if.pc[31:0]" ...
];
% Individual PC bits (0..31) — will be found programmatically

% 3) Resolve each alias against the header (try with and without space)
res.clk    = first_match(aliases.clk);
res.branch = first_match(aliases.branch);
res.stall  = first_match(aliases.stall);

% forwardA
res.fwdA_bus   = first_match(aliases.fwdA_bus);
res.fwdA_bits  = bit_matches("forwardA", 1:-1:0);

% forwardB
res.fwdB_bus   = first_match(aliases.fwdB_bus);
res.fwdB_bits  = bit_matches("forwardB", 1:-1:0);

% pc
res.pc_bus     = first_match(aliases.pc_bus);
res.pc_bits    = bit_matches("pc", 31:-1:0);

% Print what we resolved
disp('--- Resolved names ---');
print_res('clk',res.clk);
print_res('branch_taken',res.branch);
print_res('stall',res.stall);
print_res('forwardA_bus',res.fwdA_bus);
print_list('forwardA_bits', res.fwdA_bits);
print_res('forwardB_bus',res.fwdB_bus);
print_list('forwardB_bits', res.fwdB_bits);
print_res('pc_bus',res.pc_bus);
print_list('pc_bits', res.pc_bits);

% 4) Parse the signals using parse_vcd_signals
need_any = ~isempty(res.clk) || ~isempty(res.branch) || ~isempty(res.stall) ...
         || ~isempty(res.fwdA_bus) || ~isempty(res.fwdA_bits) ...
         || ~isempty(res.fwdB_bus) || ~isempty(res.fwdB_bits) ...
         || ~isempty(res.pc_bus)   || ~isempty(res.pc_bits);

assert(need_any, 'None of the requested signals were found in the VCD header.');

wanted = string.empty(0,1);
wanted = add_if_nonempty(wanted, res.clk, res.branch, res.stall, ...
                         res.fwdA_bus, res.fwdB_bus, res.pc_bus, ...
                         res.fwdA_bits, res.fwdB_bits, res.pc_bits);

% Try parsing with both with-space and no-space forms
try
    sigs = parse_vcd_signals(vcd_path, cellstr(wanted));
catch
    wanted2 = regexprep(wanted,'\s+\[','[');
    sigs = parse_vcd_signals(vcd_path, cellstr(wanted2));
end

% 5) Convert parsed signals into numeric timelines
clk_t  = []; clk_v = [];
if ~isempty(res.clk)
    [clk_t, clk_v] = get_scalar(sigs, res.clk);
end

[branch_t, branch_v] = get_scalar(sigs, res.branch);
[stall_t,  stall_v ] = get_scalar(sigs, res.stall );

% forwardA
fwdA = get_2bit(sigs, res.fwdA_bus, res.fwdA_bits, "forwardA");

% forwardB
fwdB = get_2bit(sigs, res.fwdB_bus, res.fwdB_bits, "forwardB");

% PC (bus or bits)
pc = get_bus(sigs, res.pc_bus, res.pc_bits, "pc");

% 6) Plot
figure('Name','CPU Dashboard','Color','w');
tiledlayout(5,1,'Padding','compact','TileSpacing','compact');

% A) clk
nexttile; hold on; grid on;
if ~isempty(clk_t)
    stairs_end(clk_t, clk_v);
else
    text(0.5,0.5,'clk not found','HorizontalAlignment','center');
end
title('clk'); ylabel('lvl');

% B) branch_taken & stall
nexttile; hold on; grid on;
plot_scalar(branch_t, branch_v, 'branch\_taken');
plot_scalar(stall_t,  stall_v,  'stall');
legend('show','Location','best'); ylabel('lvl'); title('Control');

% C) forward A/B
nexttile; hold on; grid on;
plot_enum(fwdA, 'forwardA (0..3)');
plot_enum(fwdB, 'forwardB (0..3)');
legend('show','Location','best'); ylabel('sel'); title('Forwarding');

% D) PC (hex)
nexttile; hold on; grid on;
if ~isempty(pc.time)
    stairs_end(double(pc.time), double(pc.val));
    title('PC'); ylabel('value'); 
else
    text(0.5,0.5,'pc not found','HorizontalAlignment','center');
end

% E) PC (hex as text over time)
nexttile; hold on; grid on;
if ~isempty(pc.time)
    t = double(pc.time);
    v = double(pc.val);
    % Show markers + text labels
    stem(t, v, 'filled','DisplayName','pc');
    for k=1:numel(t)
        text(t(k), v(k), sprintf(' 0x%08X', v(k)),'VerticalAlignment','bottom','Interpreter','none');
    end
    title('PC (hex labels)'); ylabel('value');
else
    text(0.5,0.5,'pc not found','HorizontalAlignment','center');
end
xlabel('time');

% 7) Little summary in the command window
fprintf('\nDone. Empty subplots mean those signals weren''t in the VCD.\n');

% ================== helpers ==================
    function m = first_match(cands)
        % pick first header entry that matches any candidate (with or without space)
        m = "";
        for c = cands
            hit = any(strcmp(allhdr, c)) || any(strcmp(allhdr_nos, regexprep(c,'\s+\[','[')));
            if hit
                % return the exact header spelling (prefer with-space if present)
                idx = find(strcmp(allhdr, c), 1);
                if isempty(idx)
                    idx = find(strcmp(allhdr_nos, regexprep(c,'\s+\[','[')),1);
                    m = allhdr(idx);
                else
                    m = allhdr(idx);
                end
                return;
            end
        end
    end

    function lst = bit_matches(base, idxs)
        % find available bit names: "base [i]" or "base[i]" (flat or with hierarchy)
        lst = string.empty(0,1);
        for i = idxs
            pat1 = sprintf('%s [%d]', base, i);
            pat2 = sprintf('%s[%d]',  base, i);
            if any(strcmp(allhdr, pat1))
                lst(end+1,1) = pat1; %#ok<AGROW>
            elseif any(strcmp(allhdr, pat2))
                lst(end+1,1) = pat2; %#ok<AGROW>
            end
        end
    end

    function print_res(label, val)
        if strlength(val)>0
            fprintf('%12s: %s\n', label, val);
        else
            fprintf('%12s: (not found)\n', label);
        end
    end

    function print_list(label, L)
        if ~isempty(L)
            fprintf('%12s: {', label);
            fprintf('%s ', L);
            fprintf('}\n');
        else
            fprintf('%12s: (none)\n', label);
        end
    end

    function arr = add_if_nonempty(arr, varargin)
        for x = varargin
            val = x{1};
            if isstring(val) || ischar(val)
                if strlength(val)>0, arr(end+1,1) = string(val); end %#ok<AGROW>
            elseif iscellstr(val) || isstring(val)
                if ~isempty(val), arr = [arr; string(val(:))]; end %#ok<AGROW>
            end
        end
    end

    function [t,v] = get_scalar(sigs, name)
        t = []; v = [];
        if strlength(name)==0, return; end
        s = find_sig(sigs, name);
        if isempty(s), return; end
        [t,v] = coerce_scalar(s);
    end

    function enum = get_2bit(sigs, busname, bitnames, dispname)
        enum.time = []; enum.val = []; enum.name = dispname;
        if strlength(busname)>0
            s = find_sig(sigs, busname);
            if ~isempty(s)
                [enum.time, enum.val] = coerce_bus_to_uint(s, 2);
                return;
            end
        end
        if numel(bitnames)>=2
            s1 = find_sig(sigs, bitnames(1));
            s0 = find_sig(sigs, bitnames(2));
            if ~isempty(s1) && ~isempty(s0)
                [t1,v1] = coerce_scalar(s1);
                [t0,v0] = coerce_scalar(s0);
                [tt, vv] = align_binary_bits({t1,t0},{v1,v0});
                enum.time = tt;
                enum.val  = vv(:,1)*2 + vv(:,2); % [msb lsb]
                return;
            end
        end
    end

    function bus = get_bus(sigs, busname, bitnames, dispname)
        bus.time = []; bus.val = []; bus.name = dispname;
        if strlength(busname)>0
            s = find_sig(sigs, busname);
            if ~isempty(s)
                [bus.time, bus.val] = coerce_bus_to_uint(s, 32);
                return;
            end
        end
        if ~isempty(bitnames)
            T = cell(numel(bitnames),1);
            V = cell(numel(bitnames),1);
            ok = true;
            for k = 1:numel(bitnames)
                sk = find_sig(sigs, bitnames(k));
                if isempty(sk), ok=false; break; end
                [T{k}, V{k}] = coerce_scalar(sk);
            end
            if ok
                [tt, vv] = align_binary_bits(T, V); % vv columns are bits [bN ... b0]
                % Rebuild numeric: assume bitnames given hi..lo order
                nb = numel(bitnames);
                val = zeros(size(vv,1),1);
                for b = 1:nb
                    val = val*2 + vv(:,b);
                end
                bus.time = tt;
                bus.val  = val;
            end
        end
    end

    function s = find_sig(sigs, name)
        s = [];
        names = string({sigs.name});
        idx = find(names == name, 1);
        if isempty(idx)
            % try no-space bracket match
            nm = regexprep(name,'\s+\[','[');
            idx = find(names == nm, 1);
        end
        if ~isempty(idx), s = sigs(idx); end
    end

    function [t,v] = coerce_scalar(s)
        t = double(s.time(:));
        vraw = s.val;
        if iscell(vraw)
            v = zeros(numel(vraw),1);
            for i=1:numel(vraw)
                v(i) = parse_logic_char(vraw{i});
            end
        else
            v = double(vraw(:));
            if any(v>1 | v<0)
                % treat as logical threshold
                v = (v~=0);
            end
        end
    end

    function [t,v] = coerce_bus_to_uint(s, width)
        t = double(s.time(:));
        vraw = s.val;
        if iscell(vraw)
            % Expect binary strings like '1010...'
            v = zeros(numel(vraw),1);
            for i=1:numel(vraw)
                v(i) = binstr_to_uint(vraw{i});
            end
        else
            % Already numeric (rare)
            v = double(vraw(:));
        end
        % mask to width if necessary
        v = bitand(v, 2^width - 1);
    end

    function u = binstr_to_uint(b)
        % accept e.g. '1010', 'x', 'z', etc.
        if isempty(b) || any(b=='x' | b=='X' | b=='z' | b=='Z')
            u = NaN;
            return;
        end
        u = 0;
        for k=1:numel(b)
            u = bitshift(u,1) + (b(k)=='1');
        end
    end

    function [tt, vv] = align_binary_bits(Ts, Vs)
        % union of all edge times; step-hold the values
        times = unique(sort(vertcat(Ts{:})));
        nb = numel(Ts);
        vv = zeros(numel(times), nb);
        for b = 1:nb
            t = Ts{b}; v = Vs{b};
            vv(:,b) = step_hold(times, t, v);
        end
        tt = times;
    end

    function y = step_hold(Tq, t, v)
        % step-hold sample v(t) onto query times Tq
        y = zeros(numel(Tq),1);
        if isempty(t)
            return;
        end
        vi = 1;
        for i=1:numel(Tq)
            while vi+1<=numel(t) && t(vi+1)<=Tq(i)
                vi = vi+1;
            end
            y(i) = v(vi);
        end
    end

    function stairs_end(t, v)
        if isempty(t), return; end
        stairs([t; t(end)+1], [v; v(end)]);
    end

    function plot_scalar(t, v, nm)
        if ~isempty(t)
            stairs_end(t, v);
            set(get(get(gca,'Children'),'DisplayName'), 'DisplayName', nm); %#ok<GFLD>
        else
            text(0.5,0.5,[nm ' not found'],'HorizontalAlignment','center');
        end
    end

    function plot_enum(sig, nm)
        if ~isempty(sig.time)
            stairs_end(double(sig.time), double(sig.val));
            set(get(get(gca,'Children'),'DisplayName'), 'DisplayName', nm); %#ok<GFLD>
        else
            text(0.5,0.5,[nm ' not found'],'HorizontalAlignment','center');
        end
    end

    function d = parse_logic_char(c)
        % map '0','1','x','z' -> 0,1,NaN,NaN
        if isstring(c) || ischar(c), c = char(c); end
        switch c
            case {'0'}, d = 0;
            case {'1'}, d = 1;
            otherwise,  d = NaN;
        end
    end
end
