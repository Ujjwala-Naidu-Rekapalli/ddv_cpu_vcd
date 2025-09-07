// Detects classic load-use hazard and issues a single-cycle stall
// by deasserting PC/IF-ID writes and flushing ID/EX.
module hazard_unit (
    input  logic        id_ex_memRead,   // 1 if ID/EX is a load
    input  logic [4:0]  id_ex_rd,        // dest reg of the load in EX
    input  logic [4:0]  if_id_rs1,       // source regs of instr in ID
    input  logic [4:0]  if_id_rs2,
    output logic        stall,           // convenience OR of stall signals
    output logic        pc_write,        // gate PC update (0 = hold)
    output logic        if_id_write,     // gate IF/ID reg write (0 = hold)
    output logic        id_ex_flush      // bubble the ID/EX stage
);
    always_comb begin
        stall      = 1'b0;
        pc_write   = 1'b1;
        if_id_write= 1'b1;
        id_ex_flush= 1'b0;

        if (id_ex_memRead && (id_ex_rd != 5'd0) &&
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            stall       = 1'b1;
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            id_ex_flush = 1'b1;
        end
    end
endmodule

