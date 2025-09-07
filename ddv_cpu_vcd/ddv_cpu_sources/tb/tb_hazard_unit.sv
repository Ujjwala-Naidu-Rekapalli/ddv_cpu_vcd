`timescale 1ns/1ps
module tb_hazard_unit;
    logic        id_ex_memRead;
    logic [4:0]  id_ex_rd, if_id_rs1, if_id_rs2;
    logic        stall, pc_write, if_id_write, id_ex_flush;

    hazard_unit dut(
        .id_ex_memRead, .id_ex_rd, .if_id_rs1, .if_id_rs2,
        .stall, .pc_write, .if_id_write, .id_ex_flush
    );

    int fails = 0;

    // Avoid 'expect' keyword; use 'chk'
    task automatic chk(string name, bit st, bit pcw, bit ifw, bit fl,
                       bit est, bit epcw, bit eifw, bit efl);
        if (st!==est || pcw!==epcw || ifw!==eifw || fl!==efl) begin
            $display("[FAIL] %s: stall=%0b pc_write=%0b if_id_write=%0b id_ex_flush=%0b (exp %0b %0b %0b %0b)",
                      name, st,pcw,ifw,fl, est,epcw,eifw,efl);
            fails = fails + 1;
        end else begin
            $display("[ OK ] %s: stall=%0b pc_write=%0b if_id_write=%0b id_ex_flush=%0b",
                      name, st,pcw,ifw,fl);
        end
    endtask

    initial begin
        // No hazard
        id_ex_memRead=0; id_ex_rd=5'd3; if_id_rs1=5'd1; if_id_rs2=5'd2; #1;
        chk("no hazard", stall,pc_write,if_id_write,id_ex_flush, 0,1,1,0);

        // Load-use on RS1
        id_ex_memRead=1; id_ex_rd=5'd1; if_id_rs1=5'd1; if_id_rs2=5'd9; #1;
        chk("load-use RS1", stall,pc_write,if_id_write,id_ex_flush, 1,0,0,1);

        // Load-use on RS2
        id_ex_rd=5'd2; if_id_rs1=5'd10; if_id_rs2=5'd2; #1;
        chk("load-use RS2", stall,pc_write,if_id_write,id_ex_flush, 1,0,0,1);

        // RD==x0 should not trigger
        id_ex_memRead=1; id_ex_rd=5'd0; if_id_rs1=5'd0; if_id_rs2=5'd0; #1;
        chk("x0 ignored", stall,pc_write,if_id_write,id_ex_flush, 0,1,1,0);

        if (fails==0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fails);
            $fatal(1);
        end
        $finish;
    end
endmodule

