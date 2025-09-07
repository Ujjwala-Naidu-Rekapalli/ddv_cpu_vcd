function [factor_sec, label] = vcd_read_timescale(vcd_file)
% Return conversion factor (to seconds) and a pretty label from VCD $timescale

factor_sec = 1e-9;  % default 1 ns
label = 'ns';

fid = fopen(vcd_file,'r');
if fid<0, warning('Could not open VCD for timescale, defaulting to ns'); return; end
clean = onCleanup(@() fclose(fid));

while true
    ln = fgetl(fid);
    if ~ischar(ln), break; end
    if contains(ln, '$timescale')
        % read next line(s) until we see $end
        ts = ln;
        while ~contains(ts, '$end')
            ln = fgetl(fid);
            if ~ischar(ln), break; end
            ts = [ts ' ' ln]; %#ok<AGROW>
        end
        % examples: "$timescale 1ns $end", "$timescale 10 ps $end"
        tok = regexp(ts, '\$timescale\s+(\d+)\s*([munpf]s)\s*\$end', 'tokens', 'once');
        if isempty(tok)
            % sometimes units are like s, ms, us, ns, ps, fs without a leading digit spacing
            tok = regexp(ts, '\$timescale\s+(\d+)\s*([a-z]+)\s*\$end', 'tokens', 'once');
        end
        if ~isempty(tok)
            mult = str2double(tok{1});
            unit = tok{2};
            switch lower(unit)
                case 's',  base = 1;
                case 'ms', base = 1e-3;
                case 'us', base = 1e-6;
                case 'ns', base = 1e-9;
                case 'ps', base = 1e-12;
                case 'fs', base = 1e-15;
                otherwise, base = 1e-9; unit = 'ns';
            end
            factor_sec = mult * base;
            % choose a nice label we’ll render later (ns/us/ms)
            if factor_sec >= 1e-3
                label = 'ms';
            elseif factor_sec >= 1e-6
                label = 'us';
            else
                label = 'ns';
            end
        end
        break
    end
    % stop when header ends
    if contains(ln, '$enddefinitions'), break; end
end
end

