function vars = vcd_list_vars(vcd_file, varargin)
%VCD_LIST_VARS List all variable names in a VCD file
%
%   vars = vcd_list_vars(vcd_file)
%   vars = vcd_list_vars(vcd_file, 'prefix','/tb_uvm_cpu/mon_if/')

    p = inputParser;
    addRequired(p,'vcd_file',@ischar);
    addParameter(p,'prefix','',@ischar);
    parse(p,vcd_file,varargin{:});
    prefix = p.Results.prefix;

    fid = fopen(vcd_file,'r');
    assert(fid>0,'Cannot open %s',vcd_file);
    vars = {};
    while true
        t = fgetl(fid);
        if ~ischar(t), break; end
        if startsWith(strtrim(t),'$var')
            C = strsplit(strtrim(t));
            full_name = strjoin(C(4:end-1),' ');
            if isempty(prefix) || contains(full_name,prefix)
                vars{end+1,1} = full_name; %#ok<AGROW>
            end
        elseif contains(t,'$enddefinitions')
            break;
        end
    end
    fclose(fid);
end

