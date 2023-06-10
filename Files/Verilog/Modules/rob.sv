/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  rob.sv                                              //
//                                                                     //
//  Description :  re-order buffer                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module rob (
    input                                              clock, 
    input                                              reset,
    input  DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_dispatch_in,
    input  COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in,

    output ROB_DISPATCH_PACKET                         rob_dispatch_out,  // stalls and new entry indices from ROB
    output ROB_PACKET          [`SUPERSCALAR_WAYS-1:0] rob_retire_out

  `ifdef TEST_MODE
  , output ROB_PACKET          [`N_ROB_ENTRIES-1:0]    rob_table
  `endif
);
    // ROB State
    ROB_PACKET [`N_ROB_ENTRIES-1:0]                        rob, next_rob;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        head_idx, next_head_idx;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        tail_idx, next_tail_idx;
    logic                                                  empty, next_empty;

    // Internal wires
    logic [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] d_idx, c_idx, r_idx; 
    logic [`SUPERSCALAR_WAYS-1:0]                          dispatch_en, retire_en; 

  `ifdef TEST_MODE
    assign rob_table  = rob;
  `endif

    always_ff @(posedge clock) begin        
        if (reset) begin
            rob      <= `SD '0;
            head_idx <= `SD '0;
            tail_idx <= `SD '0;
            empty    <= `SD `TRUE;
        end  // if (reset)
        else begin
            rob      <= `SD next_rob;
            head_idx <= `SD next_head_idx;
            tail_idx <= `SD next_tail_idx;
            empty    <= `SD next_empty;
        end  // if (~reset)
    end  // always_ff @(posedge clock)

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            r_idx[i] = head_idx + i;
    end  // always_comb  // r_idx

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            c_idx[i] = rob_complete_in[i].rob_idx;
    end  // always_comb  // c_idx

    always_comb begin
        retire_en[0] = (rob[r_idx[0]].complete & ~empty);
        for (int i = 1; i < `SUPERSCALAR_WAYS; i++)
            retire_en[i] = (retire_en[i - 1] & rob[r_idx[i]].complete & 
                            ~rob[r_idx[i - 1]].precise_state_enable & ~rob[r_idx[i - 1]].halt &
                            ((r_idx[i] < tail_idx) | (tail_idx < head_idx)));
    end  // always_comb  // retire_en

    always_comb begin
        next_head_idx    = head_idx;
        next_tail_idx    = tail_idx;
        next_empty       = empty;
        dispatch_en      = '0;
        rob_dispatch_out = '0;
        rob_retire_out   = '0;

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (retire_en[i]) begin
                rob_retire_out[i] = rob[r_idx[i]];

                if (next_head_idx == tail_idx)
                    next_empty = `TRUE;
                else next_head_idx++;
            end  // if the instruction is ready to be retired
        end  // for retire

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (rob_dispatch_in[i].valid) begin
                if (((next_tail_idx + 1) == next_head_idx) |
                    ((next_tail_idx == (`N_ROB_ENTRIES - 1)) & (next_head_idx == 0)))
                    rob_dispatch_out.stall[i] = `TRUE;
                else if (rob_dispatch_in[i].enable) begin
                    // Increment the tail pointer iff the ROB isn't empty
                    if (~next_empty)
                        next_tail_idx++;

                    d_idx[i]                          = next_tail_idx;
                    dispatch_en[i]                    = `TRUE;
                    rob_dispatch_out.new_entry_idx[i] = next_tail_idx;
                    rob_dispatch_out.stall[i]         = `FALSE;
                    next_empty                        = `FALSE;
                end  // if the instruction is valid, enabled, and there's room in the ROB
            end  // if the instruction is valid
        end  // for dispatch
    end  // always_comb  // output

    always_comb begin
        next_rob = rob;

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (retire_en[i])
                next_rob[r_idx[i]] = '0;
        end  // for retire

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (rob_complete_in[i].complete) begin
                next_rob[c_idx[i]].complete             = `TRUE;
                next_rob[c_idx[i]].dest_value           = rob_complete_in[i].dest_value;
                next_rob[c_idx[i]].precise_state_enable = rob_complete_in[i].precise_state_enable;
                next_rob[c_idx[i]].target_pc            = rob_complete_in[i].target_pc;
            end  // if (rob_complete_in[i].valid)
        end  // for complete

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (dispatch_en[i]) begin
                // Add the instruction in at the tail
                next_rob[d_idx[i]].t_idx    = rob_dispatch_in[i].t_idx;
                next_rob[d_idx[i]].told_idx = rob_dispatch_in[i].told_idx;
                next_rob[d_idx[i]].ar_idx   = rob_dispatch_in[i].ar_idx;
                next_rob[d_idx[i]].halt     = rob_dispatch_in[i].halt;
                next_rob[d_idx[i]].NPC      = rob_dispatch_in[i].NPC;

                // Mark the instruction as uncompleted and not a taken branch
                next_rob[d_idx[i]].complete             = `FALSE;
                next_rob[d_idx[i]].precise_state_enable = `FALSE;
                next_rob[d_idx[i]].dest_value           = '0;
                next_rob[d_idx[i]].target_pc            = '0;
            end  // if (dispatch_en[i])
        end  // for dispatch
    end  // always_comb  // next_rob
endmodule  // rob