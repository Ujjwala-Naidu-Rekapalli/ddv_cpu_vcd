function plot_pc_from_vcd_standalone(vcd_path)
% Stand-alone PC plotter that parses a VCD without any helper toolbox.
% It finds a 'pc' vector in the monitor path (flexible matching), reads
% vector value changes, converts to decimal, honors $timescale, and plots.

if nargin==0
    vcd_path = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');
end
assert(exist(vcd_path,'file')==2, 'VCD not found: %s', vcd_path);

[factor_sec, ~] = read_timescale(vcd_path);

% ---------- 1) Scan header: collect all $var lines and pick a PC candidate ----------
fid = fopen(vcd_path,'r');  assert(fid>0);
cleanup = onCleanup(@() fclose(fid));

varLines = {};
while true
    ln = fgetl(fid);
    if ~ischar(ln), error('Unexpected EOF before $enddefinitions'); end
    if contains(ln,'$var')
        % Accumulate until $end (rare multiline formatting)
        buf = ln;
        while ~contains(buf,'$end')
            ln2 = fgetl(fid);
            if ~ischar(ln2), break; end
            buf = [buf ' ' ln2]; %#ok<AGROW>
        end
        varLines{end+1} = strtrim(buf); %#ok<AGROW>
    elseif contains(ln,'$enddefinitions')
        break
    end
end

% Extract (width,id,ref) triples
Vars = struct('w',{},'id',{},'ref',{});
for i = 1:numel(varLines)
    tok = regexp(varLines{i}, '^\s*\$var\s+\w+\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end\s*$', 'tokens','once');
    if ~isempty(tok)
        Vars(end+1).w  = str2double(tok{1}); %#ok<AGROW>
        Vars(end).id   = tok{2};
        Vars(end).ref  = strtrim(tok{3});
    end
end

% Flexible matches for pc bus:
% accept slash or dot scopes, optional leading '/', optional space before [..],
% look for mon_if.*pc if present; otherwise any .../pc[..] vector.
isPC = false(1,numel(Vars));

% 1) prefer monitor-path “mon_if” + “pc”
for i = 1:numel(Vars)
    r = Vars(i).ref;
    r_nos = regexprep(r,'\s+\[','['); % drop space before bracket for matching
    if ~isempty(regexp(r_nos, '(mon_if[./].*pc\[\d+:\d+\])|(mon_if.*pc\s*\[\d+:\d+\])', 'once'))
        isPC(i) = true;
    end
end

% 2) if nothing yet, accept any .../pc[..] vector
if ~any(isPC)
    for i = 1:numel(Vars)
        r = Vars(i).ref;
        r_nos = regexprep(r,'\s+\[','[');
        if ~isempty(regexp(r_nos, '(^|[./])pc\[\d+:\d+\]$', 'once'))
            isPC(i) = true;
        end
    end
end

pc_idx = find(isPC, 1, 'first');
if isempty(pc_idx)
    % Help the user: print candidates that contain 'pc' (vector) so they can see names
    candidates = {};
    for i = 1:numel(Vars)
        if contains(lower(Vars(i).ref), 'pc') && contains(Vars(i).ref,'[')
            candidates{end+1} = sprintf('w=%d  id=%s  ref=%s', Vars(i).w, Vars(i).id, Vars(i).ref); %#ok<AGROW>
        end
    end
    fprintf(2,'\nCould not auto-find a PC bus in the VCD header.\n');
    if ~isempty(candidates)
        fprintf(2,'Here are header variables that contain "pc":\n');
        fprintf(2,'  %s\n', strjoin(candidates, '\n  '));
    else
        fprintf(2,'No header variables containing "pc" were found.\n');
    end
    error('No PC vector ($var ... pc [N:M] ...) found. If your name is different, please tell me the exact ref from the list above.');
end

pc_id   = Vars(pc_idx).id;
pc_bits = Vars(pc_idx).w;
pc_name = Vars(pc_idx).ref;
assert(pc_bits>0, 'PC width not parsed.');

% ---------- 2) Parse value changes for that id ----------
t_raw   = [];            % integer times (VCD ticks)
val_dec = [];            % decimal PC values
cur_time = 0;

while true
    ln = fgetl(fid);
    if ~ischar(ln), break; end
    if isempty(ln), continue; end

    c = ln(1);
    if c == '#'
        tt = sscanf(ln(2:end), '%d', 1);
        if ~isempty(tt), cur_time = tt; end

    elseif (c=='b' || c=='B')
        parts = regexp(strtrim(ln), '^\s*[bB]([01xXzZ]+)\s+(\S+)\s*$', 'tokens','once');
        if ~isempty(parts)
            binstr = parts{1};
            vid    = parts{2};
            if strcmp(vid, pc_id)
                binstr = regexprep(binstr,'[xXzZ]','0');   % map x/z -> 0
                % binary to decimal
                d = 0;
                for k = 1:numel(binstr)
                    d = d*2 + (binstr(k)=='1');
                end
                t_raw(end+1,1)   = cur_time; %#ok<AGROW>
                val_dec(end+1,1) = d;        %#ok<AGROW>
            end
        end
    end
end
assert(~isempty(t_raw), 'No PC value changes were found for id "%s" (%s).', pc_id, pc_name);

% ---------- 3) Convert time to pretty units ----------
t_sec = double(t_raw) * factor_sec;
if max(t_sec) >= 1e-3
    t = t_sec*1e3; xlab = 'time (ms)';
elseif max(t_sec) >= 1e-6
    t = t_sec*1e6; xlab = 'time (us)';
else
    t = t_sec*1e9; xlab = 'time (ns)';
end

% ---------- 4) Plot ----------
figure('Name','Program Counter (from VCD)');
stairs([t; t(end)+eps], [val_dec; val_dec(end)], 'LineWidth', 1.2);
grid on
xlabel(xlab)
ylabel('PC (decimal)')
title(sprintf('Program Counter — %s', pc_name), 'Interpreter','none');

end

function [factor_sec, label] = read_timescale(vcd_file)
% Minimal $timescale reader (seconds per tick, and label suggestion)
factor_sec = 1e-9; label = 'ns';  % default
fid = fopen(vcd_file,'r'); if fid<0, return; end
c = onCleanup(@() fclose(fid));
while true
    ln = fgetl(fid);
    if ~ischar(ln), break; end
    if contains(ln,'$timescale')
        ts = ln;
        while ~contains(ts,'$end')
            ln2 = fgetl(fid);
            if ~ischar(ln2), break; end
            ts = [ts ' ' ln2]; %#ok<AGROW>
        end
        tok = regexp(ts, '\$timescale\s+(\d+)\s*([a-zA-Z]+)\s*\$end', 'tokens','once');
        if ~isempty(tok)
            mult = str2double(tok{1});
            unit = lower(tok{2});
            switch unit
                case 's',  base = 1;
                case 'ms', base = 1e-3;
                case 'us', base = 1e-6;
                case 'ns', base = 1e-9;
                case 'ps', base = 1e-12;
                case 'fs', base = 1e-15;
                otherwise, base = 1e-9;
            end
            factor_sec = mult*base;
            if factor_sec >= 1e-3, label='ms';
            elseif factor_sec >= 1e-6, label='us';
            else, label='ns'; end
        end
        break
    end
    if contains(ln,'$enddefinitions'), break; end
end
end
