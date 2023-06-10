/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  decoder.sv                                          //
//                                                                     //
//  Description :  decoder for the dispatch stage of the pipeline;     // 
//                 given instruction bits IR, produce the appropriate  //
//                 datapath control signals                            //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module decoder (
    input  FETCH_DISPATCH_PACKET        fetch_packet,

    output ALU_OPA_SELECT               opa_select,
    output ALU_OPB_SELECT               opb_select,
    output ALU_FUNC                     alu_func,
    output MULT_FUNC                    mult_func,
    output logic [`N_ARCH_REG_BITS-1:0] dest_reg,
    output logic [`N_ARCH_REG_BITS-1:0] sourc_reg_1,
    output logic [`N_ARCH_REG_BITS-1:0] sourc_reg_2,
    output FU_SELECT      	            fu_sel,
    output OP_SELECT	  	            op_sel,
    output logic                        rd_mem,
    output logic                        wr_mem,
    output logic                        cond_branch,
    output logic                        uncond_branch,
    output logic                        csr_op,         // used for CSR operations, a cheap way to get the return code out
    output logic                        halt,           // non-zero on a halt
    output logic                        illegal,        // non-zero on an illegal instruction
    output logic                        valid_inst      // for counting valid instructions executed
);
    INST  inst;
    logic valid_inst_in;

    assign inst          = fetch_packet.inst;
    assign valid_inst_in = fetch_packet.valid;
    assign valid_inst    = valid_inst_in & ~illegal;

    always_comb begin
        // default control values:
        // - valid instructions must override these defaults as necessary.
        //	 opa_select, opb_select, and alu_func should be set explicitly.
        // - invalid instructions should clear valid_inst.
        // - These defaults are equivalent to a noop
        // * see sys_defs.vh for the constants used here
        opa_select    = OPA_IS_RS1;
        opb_select    = OPB_IS_RS2;
        dest_reg      = `ZERO_REG;
        sourc_reg_1   = `ZERO_REG;
        sourc_reg_2   = `ZERO_REG;
        fu_sel        = ALU_1;
        op_sel        = alu;
        alu_func      = ALU_ADD;
        mult_func     = ALU_MUL;
        csr_op        = `FALSE;
        rd_mem        = `FALSE;
        wr_mem        = `FALSE;
        cond_branch   = `FALSE;
        uncond_branch = `FALSE;
        halt          = `FALSE;
        illegal       = `FALSE;

        if (valid_inst_in) begin
            casez (inst)
                `RV32_LUI: begin
                    fu_sel     = ALU_1;
                    op_sel     = alu;
                    dest_reg   = inst.r.rd;
                    opa_select = OPA_IS_ZERO;
                    opb_select = OPB_IS_U_IMM;
                end
                `RV32_AUIPC: begin
                    fu_sel     = ALU_1;
                    op_sel     = alu;
                    dest_reg   = inst.r.rd;
                    opa_select = OPA_IS_PC;
                    opb_select = OPB_IS_U_IMM;
                end
                `RV32_JAL: begin
                    fu_sel     = BRANCH;
                    op_sel     = br;
                    dest_reg      = inst.r.rd;
                    opa_select    = OPA_IS_PC;
                    opb_select    = OPB_IS_J_IMM;
                    uncond_branch = `TRUE;
                end
                `RV32_JALR: begin
                    fu_sel        = BRANCH;
                    op_sel        = br;
                    dest_reg      = inst.r.rd;
                    opa_select    = OPA_IS_RS1;
                    opb_select    = OPB_IS_I_IMM;
                    uncond_branch = `TRUE;
                end
                `RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
                `RV32_BLTU, `RV32_BGEU: begin
                    fu_sel      = BRANCH;
                    op_sel      = br;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_PC;
                    opb_select  = OPB_IS_B_IMM;
                    cond_branch = `TRUE;
                end
                `RV32_LB, `RV32_LH, `RV32_LW,
                `RV32_LBU, `RV32_LHU: begin
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    rd_mem      = `TRUE;
                end
                `RV32_SB, `RV32_SH, `RV32_SW: begin
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_S_IMM;
                    wr_mem      = `TRUE;
                end
                `RV32_ADDI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                end
                `RV32_SLTI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_SLT;
                end
                `RV32_SLTIU: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_SLTU;
                end
                `RV32_ANDI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_AND;
                end
                `RV32_ORI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_OR;
                end
                `RV32_XORI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_XOR;
                end
                `RV32_SLLI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_SLL;
                end
                `RV32_SRLI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_SRL;
                end
                `RV32_SRAI: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_I_IMM;
                    alu_func    = ALU_SRA;
                end
                `RV32_ADD: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_ADD;
                end
                `RV32_SUB: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SUB;
                end
                `RV32_SLT: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SLT;
                end
                `RV32_SLTU: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SLTU;
                end
                `RV32_AND: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_AND;
                end
                `RV32_OR: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_OR;
                end
                `RV32_XOR: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_XOR;
                end
                `RV32_SLL: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SLL;
                end
                `RV32_SRL: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SRL;
                end
                `RV32_SRA: begin
                    fu_sel      = ALU_1;
                    op_sel      = alu;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    alu_func    = ALU_SRA;
                end
                `RV32_MUL: begin
                    fu_sel      = MULT_1;
                    op_sel      = mult;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    mult_func   = ALU_MUL;
                end
                `RV32_MULH: begin
                    fu_sel      = MULT_1;
                    op_sel      = mult;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    mult_func   = ALU_MULH;
                end
                `RV32_MULHSU: begin
                    fu_sel      = MULT_1;
                    op_sel      = mult;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    mult_func   = ALU_MULHSU;
                end
                `RV32_MULHU: begin
                    fu_sel      = MULT_1;
                    op_sel      = mult;
                    dest_reg    = inst.r.rd;
                    sourc_reg_1 = inst.r.rs1;
                    sourc_reg_2 = inst.r.rs2;
                    opa_select  = OPA_IS_RS1;
                    opb_select  = OPB_IS_RS2;
                    mult_func   = ALU_MULHU;
                end
                `RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC:  
                    csr_op  = `TRUE;
                `WFI:  
                    halt    = `TRUE;
                default: 
                    illegal = `TRUE;
            endcase  // casez (inst)
        end  // if (valid_inst_in)
    end  // always
endmodule  // decoder