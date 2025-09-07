function plot_cpu_pc
%PLOT_CPU_PC Plot Program Counter as integer values

    vcd = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');

    % Use bus parser for PC
    pc_sig = parse_vcd_bus(vcd, '/tb_uvm_cpu/mon_if/pc [31:0]');

    figure; stairs(pc_sig.time, pc_sig.val,'LineWidth',1.5);
    xlabel('Time'); ylabel('PC value (decimal)');
    title('Program Counter (from VCD)');
    grid on;
end

