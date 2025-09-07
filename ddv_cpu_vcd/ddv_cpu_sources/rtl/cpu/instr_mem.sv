module instr_mem(
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    // 1 KB simple ROM (256 x 32b)
    logic [31:0] rom[0:255];

    // Load a default hex, but allow override via +HEX=<path>
    initial begin
        string f;                    // declare first
        f = "mem/instr_mem.hex";     // then assign
        void'($value$plusargs("HEX=%s", f));
        $display("[IMEM] Loading HEX file: %s", f);
        $readmemh(f, rom);
    end

    // Word-aligned fetch
    assign instr = rom[addr[9:2]];
endmodule

