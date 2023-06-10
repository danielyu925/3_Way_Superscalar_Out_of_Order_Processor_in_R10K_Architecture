/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  arch.sv                                             //
//                                                                     //
//  Description :  architectural map table                             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module arch (
    input                                                        clock,
    input                                                        reset,
    input  RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0]                 arch_retire_in,

    output logic         [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] arch_maptable
);
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] arch_maptable_reset;
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] arch_maptable_next;
    
    always_comb begin
        for (int i = 0; i < `N_ARCH_REG; i++)
            arch_maptable_reset[i] = i;
    end  // always_comb  //  arch_maptable_reset

    always_comb begin	
        arch_maptable_next = arch_maptable;
       	for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (arch_retire_in[i].complete)
                arch_maptable_next[arch_retire_in[i].ar_idx] = arch_retire_in[i].t_idx;
        end  // for each tag from the retire stage
    end  // always_comb  // arch_maptable_next

    always_ff @(posedge clock) begin
        if (reset)  arch_maptable <= `SD arch_maptable_reset;
        else        arch_maptable <= `SD arch_maptable_next;
    end  // always_ff @(posedge clock)
endmodule  // arch