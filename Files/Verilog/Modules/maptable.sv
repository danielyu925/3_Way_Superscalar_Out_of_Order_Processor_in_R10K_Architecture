/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  maptable.sv                                         //
//                                                                     //
//  Description :  map table                                           // 
//                 recieves a signal from the complete stage           //
//                 indicating the instructions that are done, if any   //
//                 are, and then assigns physical register indices to  //
//                 architectural register indices according to the     //
//                 signal from the dispatch stage                      //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module maptable (
    input                                                  clock, 
    input                                                  reset,
    input                                                  br_recover_enable,
    input MAPTABLE_PACKET                                  recovery_maptable,
    input CDB_PACKET                                       maptable_cdb_in,
    input DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] maptable_dispatch_in,

    output MAPTABLE_PACKET                                 maptable_out
);
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0]  map;
    logic [`N_ARCH_REG-1:0]                        done;
    logic [`SUPERSCALAR_WAYS-1:0][`N_ARCH_REG-1:0] complete_ar_idx;  // ar_idx of completed insts
    logic [`SUPERSCALAR_WAYS-1:0]                  complete_en;      // the t_idx is found and no dispatched inst uses its ar_idx    
    logic [`SUPERSCALAR_WAYS-1:0]                  dispatch_en;      // no later inst uses the same ar_idx

    assign maptable_out.map  = map;
    assign maptable_out.done = done;

    always_ff @(posedge clock) begin
        if (reset) begin
            done <= `SD { `N_ARCH_REG{`TRUE} };
            for (int i = 0; i < `N_ARCH_REG; i++)
                map[i] <= `SD i;
        end  // if (reset)
        else if (br_recover_enable) begin
            map  <= `SD recovery_maptable.map;   // recover the entire maptable from the recovery map
            done <= `SD { `N_ARCH_REG{`TRUE} };  // set all done bit to be 1
        end  // if (~reset & br_recover_enable)
        else begin
            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (dispatch_en[i]) begin
                    map[maptable_dispatch_in[i].ar_idx]  <= `SD maptable_dispatch_in[i].pr_idx;
                    done[maptable_dispatch_in[i].ar_idx] <= `SD `FALSE;
                end  // if (dispatch[i])

                if (complete_en[i]) done[complete_ar_idx[i]] <= `SD `TRUE;
            end  // for each instruction dispatched or completed
        end  // if (~reset & ~br_recover_enable)
    end  // always_ff @(posedge clock)

    // Find cdb complete_ens
    always_comb begin
        complete_en     = '0;
        complete_ar_idx = '0;

        // Search through all map entries
        for (int i = 0; i < `N_ARCH_REG; i++) begin
            // Check all cdb tags for a complete_en
            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                // Hit iff the t_idx matches and the entry isn't done (it's not from a previous inst)
                if ((map[i] == maptable_cdb_in.t_idx[j]) & ~done[i]) begin
                    complete_ar_idx[j] = i;
                    complete_en[j]     = `TRUE;

                    // Revoke complete_en if any valid dispatched inst uses the same ar_idx
                    for (int k = 0; k < `SUPERSCALAR_WAYS; k++) begin
                        if ((maptable_dispatch_in[k].ar_idx == i) & maptable_dispatch_in[k].enable)
                            complete_en[j] = `FALSE;
                    end  // for each dispatched instruction
                end  // if ((map[i] == maptable_cdb_in.t_idx[j]) & ~done[i])
            end  // for each cdb tag
        end  // for each physical register
    end  // always_comb  // complete_en

    // Find unused dispatches
    always_comb begin
        // Last inst cannot ever be overwritten, give it the default dispatch_en
        dispatch_en[`SUPERSCALAR_WAYS-1] = (maptable_dispatch_in[`SUPERSCALAR_WAYS-1].enable & 
                                            (maptable_dispatch_in[`SUPERSCALAR_WAYS-1].ar_idx != `ZERO_REG));

        // Search through the rest of the insts to see if they're overwritten
        for (int i = 0; i < (`SUPERSCALAR_WAYS - 1); i++) begin
            dispatch_en[i] = maptable_dispatch_in[i].enable & (maptable_dispatch_in[i].ar_idx != `ZERO_REG);

            // Loop through all insts that may overwrite it
            for (int j = 1; j < `SUPERSCALAR_WAYS; j++) begin
                // Revoke dispatch_en if any later, valid, dispatched instr uses the same ar_idx
                if ((i < j) & maptable_dispatch_in[j].enable &
                    (maptable_dispatch_in[j].ar_idx == maptable_dispatch_in[i].ar_idx))
                    dispatch_en[i] = `FALSE;
            end  // for each later dispatched instruction
        end  // for each dispatched instruction
    end  // always_comb  // dispatch_en
endmodule  // maptable