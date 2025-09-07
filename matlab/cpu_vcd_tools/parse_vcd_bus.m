function sig = parse_vcd_bus(vcd_file, bus_name)
%PARSE_VCD_BUS Extract a bus signal from VCD and return as integer
%   sig = parse_vcd_bus(vcd_file,'/tb_uvm_cpu/mon_if/pc [31:0]')

    fid = fopen(vcd_file,'r');
    assert(fid>0,'Cannot open %s',vcd_file);

    sig.name = bus_name;
    sig.time = [];
    sig.val  = [];

    % Regex to capture binary changes
    pat = ['^b([01xz]+)\s+(\S+)$'];
    curtime = 0;

    while true
        t = fgetl(fid);
        if ~ischar(t), break; end

        if startsWith(t,'#')
            curtime = str2double(t(2:end));

        elseif ~isempty(regexp(t,pat,'once'))
            C = regexp(t,pat,'tokens','once');
            binstr = C{1};
            % convert binary to integer (ignore x/z → 0)
            binstr(binstr=='x' | binstr=='z')='0';
            val = bin2dec(binstr);

            sig.time(end+1) = curtime;
            sig.val(end+1)  = val;
        end
    end

    fclose(fid);
end

