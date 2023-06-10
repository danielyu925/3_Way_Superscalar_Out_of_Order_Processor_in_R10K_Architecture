/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  freelist.sv                                         //
//                                                                     //
//  Description :  free register list;                                 // 
//                 allocates free registers to instructions in the     //
//                 dispatch stage, first checking the next index,      //
//                 then searching the register list, then checking     //
//                 for registers being retired in the same cycle       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module freelist (
    input                                                   clock, 
    input                                                   reset,
	input  DISPATCH_FREELIST_PACKET                         freelist_dispatch_in,
	input  RETIRE_FREELIST_PACKET   [`SUPERSCALAR_WAYS-1:0] freelist_retire_in,
    input                                                   br_recover_enable,
    input  MAPTABLE_PACKET                                  recovery_maptable,

	output FREELIST_DISPATCH_PACKET                         freelist_dispatch_out

  `ifdef TEST_MODE
  , output logic [`N_PHYS_REG-1:0]                          freelist_display
  , output logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0]   gnt_free_idx_display
  `endif
);
	logic [`N_PHYS_REG-1:0]                        freelist, next_freelist;
    logic [`N_PHYS_REG-1:0]                        available_free_idx;
    logic [`SUPERSCALAR_WAYS-1:0]                  req;
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0] gnt_free_idx;
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0] sel_req;

  `ifdef TEST_MODE
    assign freelist_display     = freelist;
    assign gnt_free_idx_display = gnt_free_idx;
  `endif

    always_comb begin
        if (br_recover_enable) begin
            for (int i = 0; i < `N_PHYS_REG; i++)
                available_free_idx[i] = `TRUE;
            for (int i = 0; i < `N_ARCH_REG; i++)
                available_free_idx[recovery_maptable.map[i]] = `FALSE;
        end  // if (br_recover_enable)
        else begin
            available_free_idx = freelist;
            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (freelist_retire_in[i].valid)
                    available_free_idx[freelist_retire_in[i].told_idx] = `TRUE;
            end  // for each retired instruction
        end  // if (~br_recover_enable)
    end  // always_comb  // available_free_idx

    always_comb begin
        sel_req[0] = available_free_idx;
        for (int i = 1; i < `SUPERSCALAR_WAYS; i++)
            sel_req[i] = (sel_req[i - 1] & ~gnt_free_idx[i - 1]);
    end  // always_comb  // sel_req

    genvar p; generate
        for (p = 0; p < `SUPERSCALAR_WAYS; p++) begin : sel
            ps_freelist ps_0 (
                .req(sel_req[p]),
                .en(`TRUE),
                .gnt(gnt_free_idx[p]), 
                .req_up(req[p])
            );
        end  // for each sel ps submodule
    endgenerate  // generate sel ps submodules

    always_comb begin
        next_freelist         = available_free_idx;
        freelist_dispatch_out = '0;

        for (int i = 0; i < `N_PHYS_REG ; i++) begin
            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (gnt_free_idx[j][i] & freelist_dispatch_in.new_pr_en[j]) begin
                    next_freelist[i]               = `FALSE;
                    freelist_dispatch_out.t_idx[j] = i;
                    freelist_dispatch_out.valid[j] = `TRUE;
                end  // if the pr is requested and granted
            end  // for each dispatched instruction
        end  // for each physical register
    end  // always_comb  // freelist_dispatch_out

    always_ff @(posedge clock) begin
        if (reset) begin
            freelist[`N_PHYS_REG-1:`N_ARCH_REG] <= `SD { (`N_PHYS_REG-`N_ARCH_REG){`TRUE} };
            freelist[`N_ARCH_REG-1:0]           <= `SD { `N_ARCH_REG{`FALSE} };
        end  // if (reset)
        else freelist <= `SD next_freelist;
    end  // always_ff @(posedge clock)
endmodule  // freelist