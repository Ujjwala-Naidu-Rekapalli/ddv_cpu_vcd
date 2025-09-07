module riscv_cpu(
    input  logic        clk,
    input  logic        rst,

    // -------- Monitor taps for UVM / visibility --------
    output logic        commit_valid,
    output logic [4:0]  commit_rd,
    output logic [31:0] commit_wdata,
    output logic [1:0]  mon_forwardA,
    output logic [1:0]  mon_forwardB,
    output logic        mon_stall,
    output logic        mon_branch_taken,
    output logic [31:0] mon_pc
);
    // ===================== IF stage =====================
    logic [31:0] pc, pc_next, instr_f;
    instr_mem IMEM(.addr(pc), .instr(instr_f));

    // Hazard control wires
    logic        stall, pc_write, if_id_write, id_ex_flush;

    // Flush on taken branch
    logic        flush_ifid;

    // ----------------- IF/ID pipeline reg ----------------
    logic [31:0] pc_d, instr_d;
    if_id IF_ID(
        .clk(clk), .rst(rst),
        .write_en(if_id_write),
        .flush(flush_ifid),
        .pc_in(pc),
        .instr_in(instr_f),
        .pc_out(pc_d),
        .instr_out(instr_d)
    );

    // ===================== Decode =====================
    // Basic field extraction
    logic [6:0] opcode_d; logic [2:0] funct3_d; logic [6:0] funct7_d;
    logic [4:0] rs1_d, rs2_d, rd_d;
    assign opcode_d = instr_d[6:0];
    assign rd_d     = instr_d[11:7];
    assign funct3_d = instr_d[14:12];
    assign rs1_d    = instr_d[19:15];
    assign rs2_d    = instr_d[24:20];
    assign funct7_d = instr_d[31:25];

    // Control + immediates
    logic branch_d, memRead_d, memWrite_d, regWrite_d, aluSrc_d;
    logic [1:0] aluOp_d;
    control CTRL(
        .opcode(opcode_d), .funct3(funct3_d), .funct7(funct7_d),
        .branch(branch_d), .memRead(memRead_d), .memWrite(memWrite_d),
        .regWrite(regWrite_d), .aluSrc(aluSrc_d), .aluOp(aluOp_d)
    );

    logic [31:0] imm_i_d, imm_s_d, imm_b_d;
    imm_gen IMM(
        .instr(instr_d),
        .imm_i(imm_i_d), .imm_s(imm_s_d), .imm_b(imm_b_d)
    );

    // Register file
    logic [31:0] rs1_val_d, rs2_val_d;
    logic        regWrite_wb;
    logic [4:0]  rd_wb;
    logic [31:0] wdata_wb;
    regfile RF(
        .clk(clk), .we(regWrite_wb),
        .rs1(rs1_d), .rs2(rs2_d),
        .rd(rd_wb), .wd(wdata_wb),
        .rd1(rs1_val_d), .rd2(rs2_val_d)
    );

    // ===================== ID/EX =====================
    logic [31:0] pc_x, rs1_val_x, rs2_val_x, imm_i_x, imm_s_x;
    logic [4:0]  rs1_x, rs2_x, rd_x;
    logic [2:0]  funct3_x;
    logic [6:0]  funct7_x;
    logic        branch_x, memRead_x, memWrite_x, regWrite_x, aluSrc_x;
    logic [1:0]  aluOp_x;

    id_ex ID_EX(
        .clk(clk), .rst(rst), .flush(id_ex_flush),
        .pc_in(pc_d), .rs1_val_in(rs1_val_d), .rs2_val_in(rs2_val_d),
        .imm_i_in(imm_i_d), .imm_s_in(imm_s_d),
        .rs1_in(rs1_d), .rs2_in(rs2_d), .rd_in(rd_d),
        .funct3_in(funct3_d), .funct7_in(funct7_d),
        .branch_in(branch_d), .memRead_in(memRead_d), .memWrite_in(memWrite_d),
        .regWrite_in(regWrite_d), .aluSrc_in(aluSrc_d), .aluOp_in(aluOp_d),

        .pc(pc_x), .rs1_val(rs1_val_x), .rs2_val(rs2_val_x),
        .imm_i(imm_i_x), .imm_s(imm_s_x),
        .rs1(rs1_x), .rs2(rs2_x), .rd(rd_x),
        .funct3(funct3_x), .funct7(funct7_x),
        .branch(branch_x), .memRead(memRead_x), .memWrite(memWrite_x),
        .regWrite(regWrite_x), .aluSrc(aluSrc_x), .aluOp(aluOp_x)
    );

    // ===================== Forwarding =====================
    logic [1:0] forwardA, forwardB;
    logic       ex_mem_regWrite_m; logic [4:0] ex_mem_rd_m;
    logic       mem_wb_regWrite_w; logic [4:0] mem_wb_rd_w;

    forward_unit FWD(
        .ex_mem_regwrite(ex_mem_regWrite_m), .ex_mem_rd(ex_mem_rd_m),
        .mem_wb_regwrite(mem_wb_regWrite_w), .mem_wb_rd(mem_wb_rd_w),
        .id_ex_rs1(rs1_x), .id_ex_rs2(rs2_x),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    // EX operand selects (with forwarding)
    logic [31:0] alu_srcA_pre, alu_srcB_pre;
    logic [31:0] ex_mem_alu_y_m, mem_wb_wdata_w;

    always_comb begin
        unique case (forwardA)
            2'b10: alu_srcA_pre = ex_mem_alu_y_m;
            2'b01: alu_srcA_pre = mem_wb_wdata_w;
            default: alu_srcA_pre = rs1_val_x;
        endcase
        unique case (forwardB)
            2'b10: alu_srcB_pre = ex_mem_alu_y_m;
            2'b01: alu_srcB_pre = mem_wb_wdata_w;
            default: alu_srcB_pre = rs2_val_x;
        endcase
    end

    // ALU control + operand2 mux
    logic [3:0]  alu_ctrl_x;
    logic [31:0] alu_in2_x;
    alu_control ALUCTRL(.aluOp(aluOp_x), .funct3(funct3_x), .funct7(funct7_x), .alu_ctrl(alu_ctrl_x));
    assign alu_in2_x = (aluSrc_x) ? imm_i_x : alu_srcB_pre;

    // ===================== Execute =====================
    logic [31:0] alu_y_x; logic zero_x;
    alu ALU(.a(alu_srcA_pre), .b(alu_in2_x), .alu_ctrl(alu_ctrl_x), .y(alu_y_x), .zero(zero_x));

    // Branch decision (BEQ only in smoke)
    logic take_b;
    branch_unit BU(.branch(branch_x), .funct3(funct3_x), .zero(zero_x), .take(take_b));

    // ===================== EX/MEM =====================
    logic [31:0] rs2_val_m;
    logic [2:0]  funct3_m;
    logic        memRead_m, memWrite_m;

    ex_mem EX_MEM(
        .clk(clk), .rst(rst),
        .alu_y_in(alu_y_x), .rs2_val_in(alu_srcB_pre),
        .rd_in(rd_x), .funct3_in(funct3_x),
        .memRead_in(memRead_x), .memWrite_in(memWrite_x), .regWrite_in(regWrite_x),

        .alu_y(ex_mem_alu_y_m), .rs2_val(rs2_val_m),
        .rd(ex_mem_rd_m), .funct3(funct3_m),
        .memRead(memRead_m), .memWrite(memWrite_m), .regWrite(ex_mem_regWrite_m)
    );

    // Data memory
    logic [31:0] mem_rdata_m;
    data_mem DMEM(
        .clk(clk),
        .memRead(memRead_m), .memWrite(memWrite_m),
        .addr(ex_mem_alu_y_m), .wdata(rs2_val_m),
        .rdata(mem_rdata_m)
    );

    // ===================== MEM/WB =====================
    logic [31:0] mem_data_w, alu_y_w;
    logic        memRead_w;

    mem_wb MEM_WB(
        .clk(clk), .rst(rst),
        .mem_data_in(mem_rdata_m), .alu_y_in(ex_mem_alu_y_m),
        .rd_in(ex_mem_rd_m),
        .regWrite_in(ex_mem_regWrite_m), .memRead_in(memRead_m),

        .mem_data(mem_data_w), .alu_y(alu_y_w),
        .rd(rd_wb), .regWrite(regWrite_wb), .memRead(memRead_w)
    );

    // WB mux + feedback into RF and forwarding unit shadow signals
    assign mem_wb_wdata_w     = (memRead_w) ? mem_data_w : alu_y_w;
    assign wdata_wb           = mem_wb_wdata_w;
    assign mem_wb_rd_w        = rd_wb;
    assign mem_wb_regWrite_w  = regWrite_wb;

    // ===================== Hazards & PC =====================
    hazard_unit HZ(
        .id_ex_memRead(memRead_x), .id_ex_rd(rd_x),
        .if_id_rs1(rs1_d), .if_id_rs2(rs2_d),
        .stall(stall), .pc_write(pc_write),
        .if_id_write(if_id_write), .id_ex_flush(id_ex_flush)
    );

    // IF/ID flushed on a taken branch
    assign flush_ifid = take_b;

    // Next PC (simple: PC+4 or branch target)
    always_comb begin
        pc_next = take_b ? (pc_x + imm_b_d) : (pc + 32'd4);
    end

    // PC register (gated by hazard unit)
    always_ff @(posedge clk or posedge rst) begin
        if (rst)        pc <= 32'h0;
        else if (pc_write) pc <= pc_next;
    end

    // ===================== Monitor tap assignments =====================
    assign commit_valid     = regWrite_wb;
    assign commit_rd        = rd_wb;
    assign commit_wdata     = wdata_wb;
    assign mon_forwardA     = forwardA;
    assign mon_forwardB     = forwardB;
    assign mon_stall        = stall;
    assign mon_branch_taken = take_b;
    assign mon_pc           = pc;

endmodule

