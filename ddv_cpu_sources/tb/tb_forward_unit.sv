`timescale 1ns/1ps
module tb_forward_unit;
    // DUT I/O
    logic        ex_mem_regwrite, mem_wb_regwrite;
    logic [4:0]  ex_mem_rd, mem_wb_rd, id_ex_rs1, id_ex_rs2;
    logic [1:0]  forwardA, forwardB;

    forward_unit dut(
        .ex_mem_regwrite, .ex_mem_rd,
        .mem_wb_regwrite, .mem_wb_rd,
        .id_ex_rs1, .id_ex_rs2,
        .forwardA, .forwardB
    );

    int fails = 0;

    // NOTE: Avoid 'expect' (reserved in old ModelSim). Use 'chk' instead.
    task automatic chk(string name, logic [1:0] a, logic [1:0] b,
                       logic [1:0] ea, logic [1:0] eb);
        if (a!==ea || b!==eb) begin
            $display("[FAIL] %s: forwardA=%b forwardB=%b (exp A=%b B=%b)", name, a,b,ea,eb);
            fails = fails + 1;
        end else begin
            $display("[ OK ] %s: forwardA=%b forwardB=%b", name, a,b);
        end
    endtask

    initial begin
        // Default — no forwarding
        ex_mem_regwrite=0; mem_wb_regwrite=0;
        ex_mem_rd=0; mem_wb_rd=0; id_ex_rs1=1; id_ex_rs2=2; #1;
        chk("none", forwardA, forwardB, 2'b00, 2'b00);

        // EX hazard on RS1 only
        ex_mem_regwrite=1; ex_mem_rd=1; id_ex_rs1=1; id_ex_rs2=3; mem_wb_regwrite=0; #1;
        chk("EX->RS1", forwardA, forwardB, 2'b10, 2'b00);

        // EX hazard on RS2 only
        ex_mem_rd=3; id_ex_rs1=4; id_ex_rs2=3; #1;
        chk("EX->RS2", forwardA, forwardB, 2'b00, 2'b10);

        // MEM hazard if EX miss
        ex_mem_regwrite=0; mem_wb_regwrite=1; mem_wb_rd=4; id_ex_rs1=4; id_ex_rs2=5; #1;
        chk("MEM->RS1", forwardA, forwardB, 2'b01, 2'b00);

        // Both available: EX wins
        ex_mem_regwrite=1; ex_mem_rd=6; id_ex_rs1=6; mem_wb_rd=6; #1;
        chk("EX wins RS1", forwardA, forwardB, 2'b10, 2'b00);

        // x0 ignored
        ex_mem_regwrite=1; ex_mem_rd=0; id_ex_rs1=0; id_ex_rs2=0; mem_wb_regwrite=1; mem_wb_rd=0; #1;
        chk("zero reg ignored", forwardA, forwardB, 2'b00, 2'b00);

        if (fails==0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fails);
            $fatal(1);
        end
        $finish;
    end
endmodule

