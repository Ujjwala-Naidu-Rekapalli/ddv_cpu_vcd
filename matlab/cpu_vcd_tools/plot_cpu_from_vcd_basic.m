function plot_cpu_from_vcd_basic
%PLOT_CPU_FROM_VCD_BASIC Quick plot of CPU monitor signals from VCD

    vcd = fullfile(getenv('HOME'),'Downloads','uvm_cpu.vcd');

    wanted = { ...
      '/tb_uvm_cpu/mon_if/clk', ...
      '/tb_uvm_cpu/mon_if/branch_taken', ...
      '/tb_uvm_cpu/mon_if/stall', ...
      '/tb_uvm_cpu/mon_if/forwardA [1:0]', ...
      '/tb_uvm_cpu/mon_if/forwardB [1:0]', ...
      '/tb_uvm_cpu/mon_if/pc [31:0]'};

    sigs = parse_vcd_basic(vcd, wanted);

    figure; hold on; grid on;
    for i = 1:numel(sigs)
        stairs(sigs(i).time, sigs(i).val, 'DisplayName', sigs(i).name);
    end
    xlabel('Time'); ylabel('Value');
    legend('show','Interpreter','none');
    title('CPU Monitor Signals (basic VCD parse)');
end

