function plot_pc_from_vcd(vcd_path)
% Robustly reconstruct and plot Program Counter as a step trace from a VCD.
% It discovers the pc bus bit names, parses bit transitions, merges time,
% converts to decimal, holds value between changes, and honors $timescale.

if nargin==0
    vcd_path = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');
end
assert(exist(vcd_path,'file')==2, 'VCD not found: %s', vcd_path);

% === You already have parse_vcd_signals.m somewhere. Make sure MATLAB sees it.
% addpath('/Users/ujjwala_nageswararao/smart_sensor_soc/sim'); % uncomment if needed

% 1) List available vars under the monitor interface (slash style)
vars = vcd_list_vars(vcd_path, 'prefix','/tb_uvm_cpu/mon_if/');
vars = vars(:);

% 2) Find the PC bus name as it appears in header
%    e.g. "/tb_uvm_cpu/mon_if/pc [31:0]"  (note the space before bracket in your file)
pc_bus = '';
for i = 1:numel(vars)
    if ~isempty(regexp(vars{i}, '/pc\s*\[\d+:\d+\]$', 'once'))
        pc_bus = vars{i};
        break
    end
end
assert(~isempty(pc_bus), 'Could not find PC bus in VCD header.');

% 3) Expand that bus into individual bit names (try both "pc [31:0]" and "pc[31:0]" notations)
tok = regexp(pc_bus, '^(.*?/pc)\s*\[(\d+):(\d+)\]$', 'tokens','once');
pc_base = tok{1};  hi = str2double(tok{2});  lo = str2double(tok{3});
idx = hi:-1:lo;

makeNames = @(base,sp) arrayfun(@(k) sprintf('%s%s[%d]', base, sp, k), idx, 'UniformOutput', false);
cands = [ makeNames(pc_base,' '), makeNames(pc_base,'') ];   % with and without the space

% 4) Parse any bit names that exist (some parsers only accept one style)
bitSigs = struct('name',{},'time',{},'val',{});
used = false(size(idx));
for style = 1:2
    names = cands( (style-1)*numel(idx)+1 : style*numel(idx) );
    try
        sigs = parse_vcd_signals(vcd_path, names);
    catch
        sigs = [];
    end
    % place into slots where they belong
    for s = 1:numel(sigs)
        nm = sigs(s).name;
        m  = regexp(nm, '\[(\d+)\]$', 'tokens','once');
        if isempty(m), continue; end
        k  = str2double(m{1});
        pos = find(idx==k,1);
        if ~isempty(pos) && ~used(pos)
            bitSigs(pos) = sigs(s);
            used(pos) = true;
        end
    end
    if all(used), break; end
end
assert(any(used), 'No PC bit signals parsed from VCD.');

% 5) Build a master change-time grid (union of all bit change times)
allT = unique( sort( double( cat(1, bitSigs.time) ) ) );
if isempty(allT), error('PC has no transitions'); end

% 6) For each bit, build zero-order-hold samples on the master grid
B = numel(bitSigs);
vals_bits = zeros(B, numel(allT));
for b = 1:B
    t  = double(bitSigs(b).time(:));
    v  = double(bitSigs(b).val(:)~=0);   % ensure 0/1
    if isempty(t)
        continue
    end
    % zero-order-hold map: for each allT, use the last v at t<=allT
    % find indices via histcounts-like trick
    [~,loc] = ismember(t, unique(t)); %#ok<ASGLU>  % ensure t monotonic
    % step through segments
    cur = 0;
    ptr = 1;
    for k = 1:numel(allT)
        while (ptr <= numel(t)) && (t(ptr) <= allT(k))
            cur = v(ptr);
            ptr = ptr + 1;
        end
        vals_bits(b,k) = cur;
    end
end

% 7) Convert to decimal value = sum( bit(b) * 2^(bit_index) )
weights = 2.^(idx);      % note: idx currently hi..lo, so this maps bit index value directly
pc_dec = weights * vals_bits;  % row vector result

% 8) Convert time units using $timescale
[factor_sec, base_label] = vcd_read_timescale(vcd_path);
t_sec = allT * factor_sec;

% Pick a prettier axis unit
if max(t_sec) >= 1e-3
    t = t_sec*1e3; xlab = 'time (ms)';
elseif max(t_sec) >= 1e-6
    t = t_sec*1e6; xlab = 'time (us)';
else
    t = t_sec*1e9; xlab = 'time (ns)';
end

% 9) Draw as a stairs (step) plot and append a final point so it holds to the end
figure('Name','Program Counter (stairs)');
stairs([t, t(end)+eps], [pc_dec, pc_dec(end)], 'LineWidth', 1.2);
grid on; xlabel(xlab); ylabel('PC (decimal)'); title('Program Counter from VCD (zero-order hold)');
end

