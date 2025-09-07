function sigs = parse_vcd_basic(vcd_file, wanted)
%PARSE_VCD_BASIC Parse selected signals from a VCD file
%   sigs = parse_vcd_basic(vcd_file, wanted)
%   wanted = {'/tb_uvm_cpu/mon_if/clk', ... }

    if ischar(wanted), wanted = {wanted}; end
    fid = fopen(vcd_file,'r');
    assert(fid>0,'Cannot open %s',vcd_file);

    id2meta = struct();
    sigs = struct('name',{},'time',{},'val',{});
    collecting = false;

    while true
        t = fgetl(fid);
        if ~ischar(t), break; end

        if startsWith(t,'$var')
            C = strsplit(strtrim(t));
            id  = C{3};
            nm  = strjoin(C(4:end-1),' ');
            id2meta.(matlab.lang.makeValidName(id)).name = nm;
        elseif contains(t,'$enddefinitions')
            collecting = true;
        elseif collecting
            if ~isempty(t) && t(1)=='#'
                curtime = str2double(t(2:end));
            elseif ~isempty(t)
                if t(1)=='b'
                    [val,id] = strtok(t(2:end));
                else
                    val = t(1); id = t(2:end);
                end
                id = strtrim(id);
                id = matlab.lang.makeValidName(id);
                if isfield(id2meta,id)
                    nm = id2meta.(id).name;
                    if any(strcmp(wanted,nm))
                        idx = find(strcmp({sigs.name},nm),1);
                        if isempty(idx)
                            idx = numel(sigs)+1;
                            sigs(idx).name = nm;
                            sigs(idx).time = [];
                            sigs(idx).val  = [];
                        end
                        sigs(idx).time(end+1) = curtime;
                        sigs(idx).val(end+1)  = str2double(val(1));
                    end
                end
            end
        end
    end
    fclose(fid);
end

