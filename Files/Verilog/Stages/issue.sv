/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  issue.sv                                            //
//                                                                     //
//  Description :  instruction issue stage of the pipeline;            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module issue (
    input  RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0]      issue_rs_in,
    input                  [`N_PHYS_REG-1:0][`XLEN-1:0] physical_register,
    output ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0]      issue_fu_out
);
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            issue_fu_out[i].NPC           = issue_rs_in[i].NPC;
            issue_fu_out[i].PC            = issue_rs_in[i].PC;
            issue_fu_out[i].opa_select    = issue_rs_in[i].opa_select;
            issue_fu_out[i].opb_select    = issue_rs_in[i].opb_select;
            issue_fu_out[i].op_sel        = issue_rs_in[i].op_sel;
            issue_fu_out[i].fu_select     = issue_rs_in[i].fu_sel;
            issue_fu_out[i].alu_func      = issue_rs_in[i].alu_func;
            issue_fu_out[i].mult_func     = issue_rs_in[i].mult_func;
            issue_fu_out[i].inst          = issue_rs_in[i].inst;
            issue_fu_out[i].pr_idx        = issue_rs_in[i].pr_idx;
            issue_fu_out[i].ar_idx        = issue_rs_in[i].ar_idx;
            issue_fu_out[i].rob_idx       = issue_rs_in[i].rob_idx;
            issue_fu_out[i].rd_mem        = issue_rs_in[i].rd_mem;
            issue_fu_out[i].wr_mem        = issue_rs_in[i].wr_mem;
            issue_fu_out[i].cond_branch   = issue_rs_in[i].cond_branch;
            issue_fu_out[i].uncond_branch = issue_rs_in[i].uncond_branch;
            issue_fu_out[i].halt          = issue_rs_in[i].halt;
            issue_fu_out[i].illegal       = issue_rs_in[i].illegal;
            issue_fu_out[i].csr_op        = issue_rs_in[i].csr_op;
            issue_fu_out[i].valid         = issue_rs_in[i].valid;
            issue_fu_out[i].rs1_value     = physical_register[issue_rs_in[i].reg1_pr_idx];
            issue_fu_out[i].rs2_value     = physical_register[issue_rs_in[i].reg2_pr_idx];
        end  // for each instruction
    end  // always_comb  // issue_fu_out
endmodule   //issue