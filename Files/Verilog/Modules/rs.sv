/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  rs.sv                                               //
//                                                                     //
//  Description :  reservation station module                          // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module rs (
    input                                             clock, 
    input                                             reset,
    input  CDB_PACKET                                 rs_cdb_in,
    input  FU_RS_PACKET                               rs_fu_in,
    input  DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] rs_dispatch_in,

    output RS_DISPATCH_PACKET                         rs_dispatch_out,  //struct stall
    output RS_ISSUE_PACKET    [`SUPERSCALAR_WAYS-1:0] rs_issue_out

`ifdef TEST_MODE
  , output DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0]     rs_table
`endif
);
    DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0]            rs_entries;    // RS table, uses one hot encoding
    logic [`SUPERSCALAR_WAYS-1:0][`N_RS_ENTRIES-1:0]  new_entry;     //e.g. [1,0,0] [15:0]
    logic [`SUPERSCALAR_WAYS-1:0][`N_RS_ENTRIES-1:0]  issue_ind;
    logic [`SUPERSCALAR_WAYS-1:0]                     not_stall;
    logic [`N_RS_ENTRIES-1:0]                         available_idx;

    assign rs_dispatch_out.stall = ~not_stall;

`ifdef TEST_MODE
    assign rs_table = rs_entries;
`endif

    always_comb begin
        for (int i = 0; i < `N_RS_ENTRIES; i++)
            available_idx[i] = ~rs_entries[i].valid;
    end  // always_comb  // available_idx

    logic [`SUPERSCALAR_WAYS-1:0][`N_RS_ENTRIES-1:0] sel_req;

    always_comb begin
        sel_req[`SUPERSCALAR_WAYS - 1] = available_idx;
        for (int i = (`SUPERSCALAR_WAYS - 1); i != 0; i--)
            sel_req[i - 1] = sel_req[i] & ~new_entry[i];
    end  // always_comb  // sel_req

    genvar s; generate
        for (s = 0; s < `SUPERSCALAR_WAYS; s++) begin
            ps_rs sel_2(
                .req(sel_req[s]), 
                .en(`TRUE), 
                .gnt(new_entry[s]), 
                .req_up(not_stall[s])
            );
        end  // for each sel ps submodule
    endgenerate  // generate sel ps submodules
    
    // Handle CDB Logic
    logic [`N_RS_ENTRIES-1:0] reg1_next_ready;
    logic [`N_RS_ENTRIES-1:0] reg2_next_ready;

    // Check CDB broadcast Tag+
    always_comb begin
        for (int i = 0; i < `N_RS_ENTRIES; i++) begin
            reg1_next_ready[i] = rs_entries[i].reg1_ready;
            reg2_next_ready[i] = rs_entries[i].reg2_ready;

            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (rs_entries[i].reg1_pr_idx == rs_cdb_in.t_idx[j])
                    reg1_next_ready[i] = `TRUE;
                if (rs_entries[i].reg2_pr_idx == rs_cdb_in.t_idx[j])
                    reg2_next_ready[i] = `TRUE;
            end  // for each CDB tag
        end  // for each rs entry
    end  // always_comb  // reg readies

    // Allocate new entry to RS
    DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0] rs_entries_next;

    always_comb begin
        for (int i = 0; i < `N_RS_ENTRIES; i++) begin
            rs_entries_next[i]            = rs_entries[i];
            rs_entries_next[i].reg1_ready = reg1_next_ready[i];
            rs_entries_next[i].reg2_ready = reg2_next_ready[i];

            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (issue_ind[j][i]) begin
                    rs_entries_next[i]        = '0;
                    rs_entries_next[i].valid  = `FALSE;
                    rs_entries_next[i].enable = `FALSE;
                end  // if (issue_ind[j][i])
            end  // for each issue_ind

            for (int j = `SUPERSCALAR_WAYS; j != 0; j--) begin
                if (new_entry[j - 1][i] & rs_dispatch_in[j - 1].enable)
                    rs_entries_next[i] = rs_dispatch_in[j - 1];
            end  // for each new entry
        end  // for each rs entry
    end  // always_comb  // rs_entries_next

    always_ff @(posedge clock) begin
        if (reset) rs_entries <= `SD '0;
        else       rs_entries <= `SD rs_entries_next;
    end  // always_ff @(posedge clock)

    // Set ISSUE packet
    logic [`N_RS_ENTRIES-1:0] tag_ready_plus;
    logic [`N_RS_ENTRIES-1:0] fu_ready_status;

    // Check reg1 & reg2 are ready (T+), consider CDB broadcast
    always_comb begin
        for (int i = 0; i < `N_RS_ENTRIES; i++)
            tag_ready_plus[i] = (reg1_next_ready[i] & reg2_next_ready[i] & rs_entries[i].valid);
    end  // always_comb  // tag_ready_plus

    FU_SELECT [`N_RS_ENTRIES-1:0] issue_fu_sel;
    logic                         alu_1_selected;
    logic                         alu_2_selected;
    logic                         alu_3_selected;
    logic                         mult_1_selected;
    logic                         mult_2_selected;
    logic                         mult_selected;
    logic                         branch_1_selected;

    // Select rs entries whose corresponding funciton unit is not busy (not full)
    always_comb begin
        fu_ready_status   = `FALSE;
        alu_1_selected    = `FALSE;
        alu_2_selected    = `FALSE;
        alu_3_selected    = `FALSE;
        mult_1_selected   = `FALSE;
        mult_2_selected   = `FALSE;
        mult_selected     = `FALSE;
        branch_1_selected = `FALSE;
        issue_fu_sel      = '0;

        for (int i = 0; i < `N_RS_ENTRIES; i++) begin
            if (tag_ready_plus[i]) begin
                case (rs_entries[i].fu_sel)
                    ALU_1: begin
                        if (~alu_1_selected & ~rs_fu_in.alu_1) begin
                            fu_ready_status[i] = `TRUE;
                            alu_1_selected     = `TRUE;
                            issue_fu_sel[i]    = ALU_1;
                        end  // if the alu_1 fu is free and not already assigned
                        else if (~alu_2_selected & ~rs_fu_in.alu_2) begin
                            fu_ready_status[i] = `TRUE;
                            alu_2_selected     = `TRUE;
                            issue_fu_sel[i]    = ALU_2;
                        end  // if the alu_2 fu is free and not already assigned
                        else if (~alu_3_selected & ~rs_fu_in.alu_3) begin
                            fu_ready_status[i] = `TRUE;
                            alu_3_selected     = `TRUE;
                            issue_fu_sel[i]    = ALU_3;
                        end  // if the alu_3 fu is free and not already assigned
                    end  // case (rs_entries[i].fu_sel == ALU_1)
                    MULT_1: begin
                        if (~rs_fu_in.mult_1 & ~rs_fu_in.mult_2 & ~mult_selected) begin
                            if (~mult_1_selected) begin
                                fu_ready_status[i] = `TRUE;
                                mult_1_selected    = `TRUE;
                                mult_selected      =  `TRUE;
                                issue_fu_sel[i]    = MULT_1;
                            end  // if the mult_1 fu is not already assigned
                            else if (~mult_2_selected) begin
                                fu_ready_status[i] = `TRUE;
                                mult_2_selected    = `TRUE;
                                mult_selected      =  `TRUE;
                                issue_fu_sel[i]    = MULT_2;
                            end  // if the mult_2 fu is not already assigned
                        end  // if the mult fu is free
                    end  // case (rs_entries[i].fu_sel == MULT_1)
                    BRANCH: begin
                        if (~branch_1_selected & ~rs_fu_in.branch_1) begin
                            fu_ready_status[i] = `TRUE;
                            branch_1_selected  = `TRUE;
                            issue_fu_sel[i]    = BRANCH;
                        end  // if the branch_1 fu is free and not already assigned
                    end  // case (rs_entries[i].fu_sel == BRANCH)
                    default: fu_ready_status[i] = `FALSE;
                endcase  // case (rs_entries[i].fu_sel)
            end  // if the instruction is ready to issue
        end  // for each rs entry
    end  // always_comb  // fu_select

    logic [`N_RS_ENTRIES-1:0]                        entry_ready;
    logic [`N_RS_ENTRIES-1:0]                        entry_ready_reverse_3;
    logic [`SUPERSCALAR_WAYS-1:0][`N_RS_ENTRIES-1:0] issue_ind_reverse;
    logic [`SUPERSCALAR_WAYS-1:0][`N_RS_ENTRIES-1:0] issue_req;
    logic [`SUPERSCALAR_WAYS-1:0]                    reverse_up;

    assign entry_ready           = tag_ready_plus & fu_ready_status;
    assign entry_ready_reverse_3 = { << {entry_ready} };              // select which entry to issue
    assign issue_ind             = { << {issue_ind_reverse} };

    always_comb begin
        issue_req[`SUPERSCALAR_WAYS - 1] = entry_ready_reverse_3;
        for (int i = (`SUPERSCALAR_WAYS - 1); i != 0; i--)
            issue_req[i - 1] = issue_req[i] & ~issue_ind_reverse[i];
    end  // always_comb  // issue_req

    genvar r; generate
        for (r = 0; r < `SUPERSCALAR_WAYS; r++) begin : issue
            ps_rs ps_0 (
                .req(issue_req[r]), 
                .en(`TRUE), 
                .gnt(issue_ind_reverse[r]),
                .req_up(reverse_up[`SUPERSCALAR_WAYS - (r + 1)])
            );
        end  // for each issue ps submodule
    endgenerate  // generate issue ps submodules

    // Assign issue packets
    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] issue_packet;

    always_comb begin
        issue_packet = '0;
        for (int i = 0; i < `N_RS_ENTRIES; i++) begin
            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (issue_ind[j][i]) begin
                    issue_packet[j]        = rs_entries[i];
                    issue_packet[j].fu_sel = issue_fu_sel[i];
                end  // if the instruction is ready to be issued
            end  // for each issue_packet
        end  // for each rs entry
    end  // always_comb  // issue_packet

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)begin
            rs_issue_out[i].valid         = issue_packet[i].valid;
            rs_issue_out[i].fu_sel        = issue_packet[i].fu_sel;
            rs_issue_out[i].op_sel        = issue_packet[i].op_sel;
            rs_issue_out[i].NPC           = issue_packet[i].NPC;
            rs_issue_out[i].PC            = issue_packet[i].PC;
            rs_issue_out[i].opa_select    = issue_packet[i].opa_select;
            rs_issue_out[i].opb_select    = issue_packet[i].opb_select;
            rs_issue_out[i].alu_func      = issue_packet[i].alu_func;
            rs_issue_out[i].mult_func     = issue_packet[i].mult_func;
            rs_issue_out[i].inst          = issue_packet[i].inst;
            rs_issue_out[i].halt          = issue_packet[i].halt;
            rs_issue_out[i].rob_idx     = issue_packet[i].rob_idx;
            rs_issue_out[i].pr_idx        = issue_packet[i].pr_idx;
            rs_issue_out[i].ar_idx        = issue_packet[i].ar_idx;
            rs_issue_out[i].reg1_pr_idx   = issue_packet[i].reg1_pr_idx;
            rs_issue_out[i].reg2_pr_idx   = issue_packet[i].reg2_pr_idx;
            rs_issue_out[i].rd_mem        = issue_packet[i].rd_mem;
            rs_issue_out[i].wr_mem        = issue_packet[i].wr_mem;
            rs_issue_out[i].cond_branch   = issue_packet[i].cond_branch;
            rs_issue_out[i].uncond_branch = issue_packet[i].uncond_branch;
            rs_issue_out[i].illegal       = issue_packet[i].illegal;
            rs_issue_out[i].csr_op        = issue_packet[i].csr_op;
        end  // for each issued instruction
    end  // always_comb  // rs_issue_out
endmodule  // rs