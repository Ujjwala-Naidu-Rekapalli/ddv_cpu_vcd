function sigs = vcd_read_signals(vcd_file, wanted)
%VCD_READ_SIGNALS Minimal VCD reader for specific signals (scalars & vectors).
%   SIGS = VCD_READ_SIGNALS(VCD_FILE, WANTED)
%   - VCD_FILE : path to .vcd
%   - WANTED   : cellstr of hierarchical names as seen in $var lines
%                (handles both "bus [31:0]" and "bus[31:0]" forms)
%   Returns struct array: sigs(i).name, .time (int64), .val
%
%   .val for scalars -> numeric 0/1
%   .val for vectors -> uint64 (interprets binary as unsigned)
%
%   This parser is simple but safe:
%     - ignores dumpvars $dump* commands
%     - handles time markers '#N'
%     - handles scalar value changes: '0<id>' '1<id>'
%     - handles vector value changes: 'b1010 <id>' (also 'B' uppercase)
%     - stores only requested IDs for compactness

    arguments
        vcd_file (1,1) string
        wanted {mustBeText} = {}
    end
    if ischar(wanted), wanted = {wanted}; end
    wanted = cellstr(wanted);

    % -------- open
    fid = fopen(vcd_file,'r');
    assert(fid>0, 'Cannot open VCD: %s', vcd_file);
    c = onCleanup(@() fclose(fid));

    % -------- normalization helpers
    nospace = @(s) regexprep(s,'\s+\[','[');
    dropleadslash = @(s) regexprep(s,'^/+','');

    norm = @(s) dropleadslash(nospace(s));

    % -------- pass 1: parse header ($var) → map id ↔ full name
    id2name = containers.Map('KeyType','char','ValueType','char');
    name2id = containers.Map('KeyType','char','ValueType','char');

    scope = "";          % track nested scopes for full hierarchical names
    scopeStack = string.empty;

    headerDone = false;

    % For speed: read line-by-line (VCDs here are small)
    fseek(fid, 0, 'bof');
    while true
        ln = fgetl(fid);
        if ~ischar(ln), break; end

        if startsWith(ln,'$scope')
            % $scope module <name> $end
            tok = regexp(ln,'^\$scope\s+\w+\s+(\S+)\s+\$end','tokens','once');
            if ~isempty(tok)
                scopeStack(end+1) = string(tok{1});
            end
            continue
        end

        if startsWith(ln,'$upscope')
            if ~isempty(scopeStack)
                scopeStack(end) = [];
            end
            continue
        end

        if startsWith(ln,'$var ')
            % Example:
            % $var wire 1 ! clk $end
            % $var wire 32 " alu_y [31:0] $end
            tok = regexp(ln,['^\$var\s+\w+\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end$'], ...
                         'tokens','once');
            if ~isempty(tok)
                % width = str2double(tok{1});
                id    = tok{2};
                tail  = tok{3}; % name possibly with "[..]"

                % full hierarchical name = scope path + tail
                if isempty(scopeStack)
                    full_name = tail;
                else
                    full_name = strjoin(scopeStack,'/');
                    if full_name(1) ~= '/'
                        full_name = "/" + full_name;
                    end
                    full_name = full_name + "/" + string(tail);
                end

                id2name(id) = char(full_name);
                name2id(norm(char(full_name))) = id; % normalized lookup too
            end
            continue
        end

        if startsWith(ln,'$enddefinitions')
            headerDone = true;
            break
        end
    end

    assert(headerDone, 'Malformed VCD: missing $enddefinitions');

    % -------- select IDs we care about
    % normalize both the wanted list and the header keys
    wanted_norm = cellfun(norm, wanted, 'UniformOutput', false);

    % try to auto-include: if wanted isempty, just return names
    if isempty(wanted_norm)
        % Return a list of available names instead of parsing waveform
        allnames = values(id2name);
        sigs = cellfun(@(n) struct('name',n,'time',int64([]),'val',[]), ...
                       allnames, 'UniformOutput', false);
        sigs = [sigs{:}];
        return
    end

    have = false(size(wanted_norm));
    ids  = strings(size(wanted_norm));
    rawNames = strings(size(wanted_norm));
    for k = 1:numel(wanted_norm)
        key = wanted_norm{k};
        if isKey(name2id, key)
            ids(k) = string(name2id(key));
            rawNames(k) = string(key);  % normalized name
            have(k) = true;
        else
            % also try without leading slash and with leading slash
            if startsWith(key,'/')
                alt = key(2:end);
            else
                alt = "/" + key;
            end
            if isKey(name2id, alt)
                ids(k) = string(name2id(alt));
                rawNames(k) = string(alt);
                have(k) = true;
            end
        end
    end

    if ~any(have)
        error('None of the requested names are present in the VCD header.');
    end

    % keep only found
    ids       = ids(have);
    rawNames  = rawNames(have);

    % create output holders
    N = numel(ids);
    sigs = repmat(struct('name','','time',int64([]),'val',[]), N, 1);
    for i = 1:N
        prettyName = nospace(char(values(id2name,{char(ids(i))})));
        sigs(i).name = prettyName;
        sigs(i).time = int64([]);
        sigs(i).val  = [];
    end

    idIndex = containers.Map('KeyType','char','ValueType','int32');
    for i = 1:N
        idIndex(char(ids(i))) = i;
    end

    % -------- pass 2: value changes
    t = int64(0);
    while true
        pos = ftell(fid);
        ln  = fgetl(fid);
        if ~ischar(ln), break; end
        if isempty(ln), continue; end

        c0 = ln(1);

        if c0 == '#'
            % time marker
            tt = sscanf(ln(2:end),'%d');
            if ~isempty(tt), t = int64(tt); end
            continue
        end

        if c0=='$'
            % skip any $dumpvars / $dumpoff / $dumpall blocks
            if startsWith(ln,'$dump')
                % consume until $end
                while ischar(ln) && ~contains(ln,'$end')
                    ln = fgetl(fid);
                end
            end
            continue
        end

        % value changes
        if c0=='0' || c0=='1' || c0=='x' || c0=='X' || c0=='z' || c0=='Z'
            % scalar: format "<bit><id>"
            % id begins immediately after first char
            id = strtrim(ln(2:end));
            if isKey(idIndex, id)
                idx = idIndex(id);
                sigs(idx).time(end+1,1) = t;
                b = c0;
                if b=='0', sigs(idx).val(end+1,1) = uint8(0);
                elseif b=='1', sigs(idx).val(end+1,1) = uint8(1);
                else
                    sigs(idx).val(end+1,1) = uint8(255); % mark X/Z as 255
                end
            end
            continue
        end

        if c0=='b' || c0=='B' || c0=='r' || c0=='R'
            % vector binary or real: "b1010 <id>"  OR  "r3.14 <id>"
            % split on whitespace
            parts = regexp(strtrim(ln),'^\w([0-9a-fA-FxXzZ\.]+)\s+(\S+)$','tokens','once');
            if isempty(parts)
                % try generic split
                parts = regexp(strtrim(ln),'\s+','split');
            end
            if numel(parts) >= 2
                valstr = parts{1};
                id = parts{2};
                if isKey(idIndex, id)
                    idx = idIndex(id);
                    sigs(idx).time(end+1,1) = t;
                    if c0=='r' || c0=='R'
                        % store NaN (not focusing on real here)
                        sigs(idx).val(end+1,1) = uint64(0);
                    else
                        % binary to uint64 (treat x/z as 0)
                        valstr = regexprep(valstr,'[xXzZ]','0');
                        if isempty(valstr)
                            sigs(idx).val(end+1,1) = uint64(0);
                        else
                            sigs(idx).val(end+1,1) = uint64(bin2dec(valstr));
                        end
                    end
                end
            end
            continue
        end

        % otherwise: ignore lines like 's' strength, or comments
        % if line starts with an identifier char (rare), ignore safely
        fseek(fid, pos, 'bof'); %#ok<UNRCH>  % (defensive, not strictly needed)
        ln = fgetl(fid); %#ok<NASGU>
    end

    % ensure each sig has at least one point if present
    for i = 1:numel(sigs)
        if isempty(sigs(i).time)
            % leave empty; caller can check
        end
    end
end
