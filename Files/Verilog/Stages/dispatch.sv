/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Module Name :  dispatch.sv                                        //
//                                                                     //
//   Description :  instruction dispatch stage of the pipeline;        // 
//                  decode instructions and add them to the ROB        //
//                  and RS                                             //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module dispatch (
    input                                                   branch_flush_en,        // branch has been taken (falsely predicted)
    input  MAPTABLE_PACKET                                  dispatch_maptable_in,                     // old map
    input  RS_DISPATCH_PACKET                               dispatch_rs_in,         // stall signal from RS
    input  ROB_DISPATCH_PACKET                              dispatch_rob_in,        // stalls and new entry indices from ROB
    input  FREELIST_DISPATCH_PACKET                         dispatch_freelist_in,   // free physical registers
    input  FETCH_DISPATCH_PACKET    [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in,
    input  CDB_PACKET                                 	    cdb_in,

    output DISPATCH_FETCH_PACKET                            dispatch_fetch_out,     // for fetch stage
    output DISPATCH_FREELIST_PACKET                         dispatch_freelist_out,  // for freelist
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out,        // for RS
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,       // for rob
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out   // new map
  `ifdef TEST_MODE
  , output logic logic_display
  `endif
);
    // Decode instructions
    logic [`SUPERSCALAR_WAYS-1:0][`N_ARCH_REG_BITS-1:0] ar_idx, reg1_ar_idx, reg2_ar_idx;
    ALU_OPA_SELECT [`SUPERSCALAR_WAYS-1:0]              opa_select;
    ALU_OPB_SELECT [`SUPERSCALAR_WAYS-1:0]              opb_select;
    FU_SELECT [`SUPERSCALAR_WAYS-1:0]                   fu_sel;
    OP_SELECT [`SUPERSCALAR_WAYS-1:0]                   op_sel;
    ALU_FUNC [`SUPERSCALAR_WAYS-1:0]                    alu_func;
    MULT_FUNC [`SUPERSCALAR_WAYS-1:0]                   mult_func;
    logic [`SUPERSCALAR_WAYS-1:0]                       csr_op;         // CSR operation (only used as a cheap way to get return code)
    logic [`SUPERSCALAR_WAYS-1:0]                       rd_mem;
    logic [`SUPERSCALAR_WAYS-1:0]                       wr_mem;
    logic [`SUPERSCALAR_WAYS-1:0]                       cond_branch;
    logic [`SUPERSCALAR_WAYS-1:0]                       uncond_branch;
    logic [`SUPERSCALAR_WAYS-1:0]                       halt;
    logic [`SUPERSCALAR_WAYS-1:0]                       illegal;
    logic [`SUPERSCALAR_WAYS-1:0]                       valid_inst;

    genvar dec; generate
        for (dec = 0; dec < `SUPERSCALAR_WAYS; dec++) begin : decoders
            decoder decode_0(
                .fetch_packet(dispatch_fetch_in[dec]),
                .opa_select(opa_select[dec]),
                .opb_select(opb_select[dec]),
                .alu_func(alu_func[dec]),
                .mult_func(mult_func[dec]),
                .fu_sel(fu_sel[dec]),
                .op_sel(op_sel[dec]),
                .rd_mem(rd_mem[dec]),
                .wr_mem(wr_mem[dec]),
                .cond_branch(cond_branch[dec]),
                .uncond_branch(uncond_branch[dec]),
                .csr_op(csr_op[dec]),
                .halt(halt[dec]),
                .illegal(illegal[dec]),
                .valid_inst(valid_inst[dec]),
                .dest_reg(ar_idx[dec]),
                .sourc_reg_1(reg1_ar_idx[dec]),
                .sourc_reg_2(reg2_ar_idx[dec])
            );
        end
    endgenerate

    // Read Map for reg1 and reg2
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0] reg1_pr_idx, reg2_pr_idx;
    logic [`SUPERSCALAR_WAYS-1:0]                  reg1_ready,  reg2_ready;

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            reg1_pr_idx[i] = dispatch_maptable_in.map[reg1_ar_idx[i]];
            reg2_pr_idx[i] = dispatch_maptable_in.map[reg2_ar_idx[i]];
            reg1_ready[i]  = dispatch_maptable_in.done[reg1_ar_idx[i]];
            reg2_ready[i]  = dispatch_maptable_in.done[reg2_ar_idx[i]];

            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (cdb_in.t_idx[j] == dispatch_maptable_in.map[reg1_ar_idx[i]])
                    reg1_ready[i] = `TRUE;
                if (cdb_in.t_idx[j] == dispatch_maptable_in.map[reg2_ar_idx[i]])
                    reg2_ready[i] = `TRUE;
            end  // for each CDB tag
        end  // for each dispatch_maptable_in
    end  // always_comb  // MAP IN

    // Get dispatch stall data
    logic [`SUPERSCALAR_WAYS_BITS-1:0] first_stall_idx;
    logic                              stall_en;
    
    assign dispatch_fetch_out.enable          = stall_en;
    assign dispatch_fetch_out.first_stall_idx = first_stall_idx;

    always_comb begin
        stall_en        = `FALSE;
        first_stall_idx = '0;

        // Find the first stalled instr, if one exists
        for (int i = `SUPERSCALAR_WAYS; i != 0; i--) begin
            if (dispatch_rs_in.stall[i - 1] | dispatch_rob_in.stall[i - 1]) begin
                stall_en        = ~branch_flush_en;
                first_stall_idx = (i - 1);
            end  // if either the rob or the rs needs a structural stall
        end  // for each instruction
    end  // always_comb  // stall

    // Get enable
    logic [`SUPERSCALAR_WAYS-1:0] enable;

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            enable[i] = (~branch_flush_en & (~stall_en | (i < first_stall_idx)));
    end  // always_comb  // enable

    // Get new_pr_en
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] pr_idx;
    logic [`SUPERSCALAR_WAYS_BITS-1:0]                  freelist_idx;

    always_comb begin
        freelist_idx = '0;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (dispatch_fetch_in[i].valid & (ar_idx[i] != `ZERO_REG)) begin
                pr_idx[i]                          = dispatch_freelist_in.t_idx[freelist_idx];
                dispatch_freelist_out.new_pr_en[i] = enable[i];
                freelist_idx++;
            end  // if the instruction is valid and has a destination register
            else begin
                pr_idx[i]                          = `ZERO_REG;
                dispatch_freelist_out.new_pr_en[i] = `FALSE;
            end  // if the instruction is invalid or doesn't have a destination register
          `ifdef TEST_MODE
            logic_display = ~stall_en;
          `endif
        end  // for each dispatch_freelist_out.new_pr_en
    end  // always_comb  // FREELIST

    // Set dispatch_rob_out
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            dispatch_rob_out[i].valid    = dispatch_fetch_in[i].valid;
            dispatch_rob_out[i].enable   = enable[i];
            dispatch_rob_out[i].t_idx    = pr_idx[i];
            dispatch_rob_out[i].told_idx = dispatch_maptable_in.map[ar_idx[i]];
            dispatch_rob_out[i].ar_idx   = dispatch_fetch_in[i].valid ? ar_idx[i] : `ZERO_REG;
            dispatch_rob_out[i].halt     = halt[i];
            dispatch_rob_out[i].NPC      = dispatch_fetch_in[i].NPC;

            for (int j = 0; j < i; j++) begin
                if (ar_idx[i] == ar_idx[j])
                    dispatch_rob_out[i].told_idx = pr_idx[j];
            end  // for each previously dispatched instruction
        end  // for each dispatch_rob_out
    end  // always_comb  // ROB

    // Set dispatch_rs_out
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            dispatch_rs_out[i].inst          = dispatch_fetch_in[i].inst;
            dispatch_rs_out[i].PC            = dispatch_fetch_in[i].PC;
            dispatch_rs_out[i].NPC           = dispatch_fetch_in[i].NPC;
            dispatch_rs_out[i].fu_sel        = fu_sel[i];
            dispatch_rs_out[i].op_sel        = op_sel[i];
            dispatch_rs_out[i].opa_select    = opa_select[i];
            dispatch_rs_out[i].opb_select    = opb_select[i];
            dispatch_rs_out[i].alu_func      = alu_func[i];
            dispatch_rs_out[i].mult_func     = mult_func[i];
            dispatch_rs_out[i].reg1_pr_idx   = reg1_pr_idx[i];
            dispatch_rs_out[i].reg2_pr_idx   = reg2_pr_idx[i];
            dispatch_rs_out[i].reg1_ready    = reg1_ready[i];
            dispatch_rs_out[i].reg2_ready    = reg2_ready[i];
            dispatch_rs_out[i].pr_idx        = pr_idx[i];
            dispatch_rs_out[i].ar_idx        = ar_idx[i];
            dispatch_rs_out[i].cond_branch   = cond_branch[i];
            dispatch_rs_out[i].uncond_branch = uncond_branch[i];
            dispatch_rs_out[i].halt          = halt[i];
            dispatch_rs_out[i].csr_op        = csr_op[i];
            dispatch_rs_out[i].rd_mem        = rd_mem[i];
            dispatch_rs_out[i].wr_mem        = wr_mem[i];
            dispatch_rs_out[i].illegal       = illegal[i];
            dispatch_rs_out[i].rob_idx       = dispatch_rob_in.new_entry_idx[i];
            dispatch_rs_out[i].enable        = enable[i];
            dispatch_rs_out[i].valid         = illegal[i] ? `FALSE : dispatch_fetch_in[i].valid;

            for (int j = 0; j < i; j++) begin
                if (reg1_ar_idx[i] == ar_idx[j]) begin
                    dispatch_rs_out[i].reg1_pr_idx = pr_idx[j];
                    dispatch_rs_out[i].reg1_ready  = `FALSE;
                end  // if reg1 is set by a previous instruction
                if (reg2_ar_idx[i] == ar_idx[j]) begin
                    dispatch_rs_out[i].reg2_pr_idx = pr_idx[j];
                    dispatch_rs_out[i].reg2_ready  = `FALSE;
                end  // if reg2 is set by a previous instruction
            end  // for each previously dispatched instruction
        end  // for each dispatch_rs_out
    end  // always_comb  // RS

    // Set dispatch_maptable_out
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            dispatch_maptable_out[i].pr_idx = pr_idx[i];
            dispatch_maptable_out[i].ar_idx = dispatch_fetch_in[i].valid ? ar_idx[i] : `ZERO_REG;
            dispatch_maptable_out[i].enable = enable[i];
        end  // for each dispatch_maptable_out
    end  // always_comb  // MAP OUT
endmodule  // dispatch