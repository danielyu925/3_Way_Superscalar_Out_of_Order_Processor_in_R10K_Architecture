/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  retire.sv                                           //
//                                                                     //
//  Description :  instruction retire stage of the pipeline;           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module retire (
    input  ROB_PACKET             [`SUPERSCALAR_WAYS-1:0]                 retire_rob_in,
    input                         [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] arch_maptable,

    output logic                                                          wfi_halt,
    output logic                  [`XLEN-1:0]                             target_pc, // target pc for precise state
    output logic                                                          br_recover_enable,
    output MAPTABLE_PACKET                                                recovery_maptable, //recover maptable
    output RETIRE_PACKET          [`SUPERSCALAR_WAYS-1:0]                 retire_out,
    output RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]                 retire_freelist_out
);
    logic [`SUPERSCALAR_WAYS-1:0] retire_en;

    // The rob will always send the top 3 instructions, regardless of if they're ready
    // we should only retire an instruction if those before it are ready 
    // (e.g., only retire retire_rob_in[2] if both retire_rob_in[0] and retire_rob_in[1] are complete
    // we also should not retire instructions following a taken branch to the recovery_maptable
    always_comb begin
        retire_en[0] = retire_rob_in[0].complete;
        for (int i = 1; i < `SUPERSCALAR_WAYS; i++)
            retire_en[i] = retire_en[i - 1] & retire_rob_in[i].complete & 
                           ~retire_rob_in[i - 1].precise_state_enable;
    end  // always_comb  // en

    always_comb begin
		wfi_halt = `FALSE;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (retire_rob_in[i].halt & retire_en[i])
                wfi_halt = `TRUE;
        end  // for each instruction
    end  // always_comb  // wfi_halt

    always_comb begin
        for (int i = 0; i < `N_ARCH_REG; i++) begin
            recovery_maptable.map[i]  = arch_maptable[i];
            recovery_maptable.done[i] = `TRUE;
        end  // for each architectural register

        br_recover_enable   = `FALSE;
        target_pc           = '0;
        retire_out          = '0;
        retire_freelist_out = '0;

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (retire_en[i]) begin
                retire_out[i].dest_value = retire_rob_in[i].dest_value;
                retire_out[i].t_idx      = retire_rob_in[i].t_idx;
                retire_out[i].ar_idx     = retire_rob_in[i].ar_idx;
                retire_out[i].NPC        = retire_rob_in[i].NPC;
                retire_out[i].complete   = `TRUE;

                retire_freelist_out[i].told_idx = retire_rob_in[i].told_idx;
                retire_freelist_out[i].valid    = `TRUE;

                if (retire_rob_in[i].precise_state_enable) begin
                    br_recover_enable = `TRUE;
                    target_pc         = retire_rob_in[i].target_pc;
                end

                recovery_maptable.map[retire_rob_in[i].ar_idx] = retire_rob_in[i].t_idx;
            end  // if the instruction is ready to retire
        end  // for each instruction
    end  // always_comb  // output
endmodule  // retire