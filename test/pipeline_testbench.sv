

module testbench;
    // //Internal Wires
    logic [63:0] tb_mem [`MEM_64BIT_LINES - 1:0];
    //counter used for when pipeline infinite loops, forces termination
    logic [63:0] debug_counter;
    
    logic [31:0] clock_count;
    logic [31:0] instr_count;
    int wb_fileno;
    int pipe_out;
    
    EXCEPTION_CODE pipeline_error_status;
    
    // //Module Wires
    logic /*clock, reset, */enable;
    //
    // //CDB_PACKET [(`N-1):0] CDB;
    //
    // logic [$clog2(`N+1)-1:0] ROB_free_entries_left;
    // logic [$clog2(`N+1)-1:0] freeList_free_entries_left;
    // logic [$clog2(`N+1)-1:0] RS_free_entries_left;
    //
    //
    //
    // logic [(`N-1):0] [`XLEN-1:0] RRAT_reg_data;
    //
    // // Wire for writeback.out
    logic [`SUPERSCALAR_WAYS_BITS-1:0] ROB_entries_retired;
   // logic [(`SUPERSCALAR_WAYS-1):0] [$clog2(`N_ARCH_REG_BITS)-1:0] ar_idx;//dest_reg_retire
    //logic [(`SUPERSCALAR_WAYS-1):0] [`XLEN-1:0] target_pc; //ROB_PC;
    //logic [(`SUPERSCALAR_WAYS-1):0] [`XLEN-1:0] ROB_retire_data;              // data of retiring entries
    // // Misspec
    // logic ROBhead_isMisspeculated;
    // logic [`XLEN-1:0] ROB_NPC;
    //
    //
    // // Debug signals
    // ROB_PACKET [`ROB_SIZE-1:0] _ROBTable;
    // logic [$clog2(`ROB_SIZE)-1:0] _ROBhead, _ROBtail, _ROBnext_head, _ROBnext_tail;
    //
    // RAT_PACKET [`ARCH_REG_SIZE-1:0] _RATOutput;
    // logic [`ARCH_REG_SIZE-1:0] [$clog2(`PHYSICAL_REG_SIZE)-1:0] _RRAT_data;
    //
    // logic [`FREELIST_SIZE-1:0] [$clog2(`PHYSICAL_REG_SIZE)-1:0] _freeListTable;
    // logic [$clog2(`FREELIST_SIZE)-1:0] _FLhead, _FLnext_head, _FLtail, _FLnext_tail;
    //
    // logic [`PHYSICAL_REG_SIZE-1:0] [`XLEN-1:0] registers_debug;
    //
    // RS_PACKET [(`RS_SIZE-1):0] _RS_Table;
    // RS_ISSUE_PACKET [(`FU_NUMS-1):0] _rs_packet_out;
    //
    // logic [1:0] _alus_en;
    // ALU_OUT_PACKET _alu_packet_out_0;
    // ALU_OUT_PACKET _alu_packet_out_1;
    // BR_OUT_PACKET _br_packet_out;
    // MEM_OUT_PACKET _mem_packet_out;
    // LSQ_OUT_PACKET _lsq_packet_out;
    // MULT_OUT_PACKET _mult_packet_out;
    // ISSUE_EX_PACKET [`FU_NUMS-1:0] _issue_ex_packet_out;
    //
    // CDB_PACKET [(`N-1):0] _CDB;
    //
    // logic [`FU_NUMS-1:0] [`XLEN-1:0] _rda_out;
    // logic [`FU_NUMS-1:0] [`XLEN-1:0] _rdb_out;
    //
    //


    //project 3
    logic clock, reset;
    logic [`SUPERSCALAR_WAYS-1:0][63:0]         Imem2proc_data;
    logic [`SUPERSCALAR_WAYS-1:0][3:0]  	    mem2proc_response;
    logic [63:0]                                  mem2proc_data;
    logic [`SUPERSCALAR_WAYS-1:0][3:0]  	    mem2proc_tag;
    logic [1:0]  							    proc2mem_command;
    logic [`XLEN-1:0] 					        proc2mem_addr;
    logic [63:0] 							    proc2mem_data;
    logic        							    halt;
    logic [2:0]  							    inst_count;

    //Test Hook

    // Outputs from Fetch-Stage
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	fetch_PC_out;
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	fetch_NPC_out;
    logic [`SUPERSCALAR_WAYS-1:0][31:0] 		fetch_IR_out;
    logic [`SUPERSCALAR_WAYS-1:0] 				fetch_valid_inst_out;

    // Outputs from Fetch/Dispatch Pipeline Register
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	fetch_dispatch_NPC_out;
    logic [`SUPERSCALAR_WAYS-1:0][31:0] 		fetch_dispatch_IR_out;
    logic [`SUPERSCALAR_WAYS-1:0] 				fetch_dispatch_valid_inst_out;


    // Outputs from Dispatch-Stage
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	dispatch_NPC_out;
    logic [`SUPERSCALAR_WAYS-1:0][31:0] 		dispatch_IR_out;
    logic [`SUPERSCALAR_WAYS-1:0] 				dispatch_valid_inst_out;

    // Outputs from Issue-Stage
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	issue_NPC_out;
    logic [`SUPERSCALAR_WAYS-1:0][31:0] 		issue_IR_out;
    logic [`SUPERSCALAR_WAYS-1:0] 				issue_valid_inst_out;

    // Outputs from Issue/Execute Pipeline Register
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	issue_execute_NPC_out;
    logic [`SUPERSCALAR_WAYS-1:0][31:0] 		issue_execute_IR_out;
    logic [`SUPERSCALAR_WAYS-1:0] 				issue_execute_valid_inst_out;


    // Outputs of FETCH stage
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0]         proc2Imem_addr;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]    fetch_packet;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]    fetch_dispatch_packet;

    // Outputs of the DISPATCH stage
    DISPATCH_FETCH_PACKET                            dispatch_fetch_packet;
    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0]       dispatch_rs_packet;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0]      dispatch_rob_packet;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_packet;
    DISPATCH_FREELIST_PACKET 			             dispatch_freelist_packet;

    // Outputs of the ISSUE stage
    ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0]          issue_packet;
    ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0]          issue_fu_packet;

    // Outputs of the EXECUTE stage
    FU_RS_PACKET                                     fu_rs_packet;
    FU_PRF_PACKET [6:0]                             fu_prf_packet;
    FU_COMPLETE_PACKET [`SUPERSCALAR_WAYS-1:0]       fu_packet;
    FU_COMPLETE_PACKET [`SUPERSCALAR_WAYS-1:0]       fu_complete_packet;

    // Outputs of the COMPLETE stage
    logic                                            branch_flush_en;
    logic [`XLEN-1:0]                                complete_target_pc;
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0]      complete_rob_packet;
    CDB_PACKET                                       cdb_packet;

    // Outputs of the RETIRE stage
    logic                                            br_recover_enable;
    MAPTABLE_PACKET                                  recovery_maptable;
    RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0]            retire_packet;
    RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]   retire_freelist_packet;

    logic retire_wfi_halt;

    // Debug display
    `ifdef TEST_MODE
    ROB_PACKET 	[`N_ROB_ENTRIES-1:0]                rob_table_display;
    ROB_PACKET 	[`SUPERSCALAR_WAYS-1:0]		        rob_retire_packet;
    ROB_DISPATCH_PACKET 	                        rob_dispatch_packet;
    RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] 		rs_issue_packet;
    DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0]       	rs_table;
    MAPTABLE_PACKET					                maptable_packet;
    logic [`N_PHYS_REG-1:0][`XLEN-1:0]              physical_register_display;
    `endif

    pipeline DUT (
                    .clock(clock),
                    .reset(reset),
                    .mem2proc_response(mem2proc_response),
                    .mem2proc_data(mem2proc_data),
                    .Imem2proc_data(Imem2proc_data),
                    .mem2proc_tag(mem2proc_tag),
                    .proc2mem_command(proc2mem_command),
                    .proc2mem_addr(proc2mem_addr),
                    .proc2mem_data(proc2mem_data),
                    .halt(halt),
                    .inst_count(inst_count) //projec3 pipeline

                    // Outputs from Fetch-Stage 
                    ,.fetch_PC_out(fetch_PC_out)
                    ,.fetch_NPC_out(fetch_NPC_out)
                    ,.fetch_IR_out(fetch_IR_out)
                    ,.fetch_valid_inst_out(fetch_valid_inst_out)

                    // Outputs from Fetch/Dispatch Pipeline Register
                    ,.fetch_dispatch_NPC_out(fetch_dispatch_NPC_out)
                    ,.fetch_dispatch_IR_out(fetch_dispatch_IR_out)
                    ,.fetch_dispatch_valid_inst_out(fetch_dispatch_valid_inst_out)

                    // Outputs from Dispatch-Stage
                    ,.dispatch_NPC_out(dispatch_NPC_out)
                    ,.dispatch_IR_out(dispatch_IR_out)
                    ,.dispatch_valid_inst_out(dispatch_valid_inst_out)


                    // Outputs from Issue-Stage
                    ,.issue_NPC_out(issue_NPC_out)
                    ,.issue_IR_out(issue_IR_out)
                    ,.issue_valid_inst_out(issue_valid_inst_out)

                    // Outputs from Issue/Execute Pipeline Register
                    ,.issue_execute_NPC_out(issue_execute_NPC_out)
                    ,.issue_execute_IR_out(issue_execute_IR_out)
                    ,.issue_execute_valid_inst_out(issue_execute_valid_inst_out),



                    // Outputs of FETCH stage
                    .proc2Imem_addr(proc2Imem_addr),
                    .fetch_packet(fetch_packet),
                    .fetch_dispatch_packet(fetch_dispatch_packet),

                    // Outputs of the DISPATCH stage
                    .dispatch_fetch_packet(dispatch_fetch_packet),
                    .dispatch_rs_packet(dispatch_rs_packet),
                    .dispatch_rob_packet(dispatch_rob_packet),
                    .dispatch_maptable_packet(dispatch_maptable_packet),
                    .dispatch_freelist_packet(dispatch_freelist_packet),

                    // Outputs of the ISSUE stage
                    .issue_packet(issue_packet),
                    .issue_fu_packet(issue_fu_packet),

                    // Outputs of the EXECUTE stage
                    .fu_rs_packet(fu_rs_packet),
                    .fu_prf_packet(fu_prf_packet),
                    .fu_packet(fu_packet),
                    .fu_complete_packet(fu_complete_packet),

                    // Outputs of the COMPLETE stage
                    .branch_flush_en(branch_flush_en),
                    .target_pc(complete_target_pc),
                    .complete_rob_packet(complete_rob_packet),
                    .cdb_packet(cdb_packet),

                    // Outputs of the RETIRE stage
                    .br_recover_enable(br_recover_enable),
                    .recovery_maptable(recovery_maptable),
                    .retire_packet(retire_packet),
                    .retire_freelist_packet(retire_freelist_packet),
		            .retire_wfi_halt(retire_wfi_halt)

                    // Testmode display
                    `ifdef TEST_MODE
                    ,.rob_table_display(rob_table_display)
                    ,.rob_retire_packet_display(rob_retire_packet)
                    ,.rob_dispatch_packet_display(rob_dispatch_packet)
		            ,.rs_issue_packet_display(rs_issue_packet)

		            ,.rs_table_display(rs_table)
		            ,.maptable_packet_display(maptable_packet)
                    ,.physical_register_display(physical_register_display)
                    `endif
    );


    // modify it for print the debug output

    function dump_output;
        $fdisplay(pipe_out, "-------------MODULES-------------");
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "Rob Table:");
                $fdisplay(pipe_out, "   | t_idx | told_idx | ar_idx | complete | halt | precise | target_pc  | dest_value |   NPC    |");
                for (int i = 0; i < `N_ROB_ENTRIES; i++)
                    $fdisplay(pipe_out, "%2d |  %2d   |    %2d    |   %2d   |    %b     |  %b   |    %b    | %d | %d | %x |",
                        i, rob_table_display[i].t_idx, rob_table_display[i].told_idx, rob_table_display[i].ar_idx, rob_table_display[i].complete, rob_table_display[i].halt, rob_table_display[i].precise_state_enable, rob_table_display[i].target_pc, rob_table_display[i].dest_value, rob_table_display[i].NPC);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "Physical Register File: PRF");
                $fdisplay(pipe_out, "   |   value    |          |   value    |          |   value    |          |   value    |");
                for (int i = 0; i < (`N_PHYS_REG / 4); i++)
                    $fdisplay(pipe_out,"%2d | %d |       %2d | %d |       %2d | %d |       %2d | %d |", 
                        i, physical_register_display[i], (i + 16), physical_register_display[i + 16], (i + 32), physical_register_display[i + 32], (i + 48), physical_register_display[i + 48]);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "RS Table:");
                $fdisplay(pipe_out, "   |   NPC    |    PC    | reg1_pr_idx | reg2_pr_idx | pr_idx | rob_idx | ar_idx |    inst    |");
                for (int i = 0; i < `N_RS_ENTRIES ; i++)
                    $fdisplay(pipe_out, "%2d | %x | %x |     %2d      |     %2d      |   %2d   |   %2d    |   %2d   | %d |",
                        i, rs_table[i].NPC, rs_table[i].PC, rs_table[i].reg1_pr_idx, rs_table[i].reg2_pr_idx, rs_table[i].pr_idx, rs_table[i].rob_idx, rs_table[i].ar_idx, rs_table[i].inst);
                
                $fdisplay(pipe_out, "   | opa_select |  opb_select | fu_sel | op_sel | alu_func | mult_func |");
                for (int i = 0; i < `N_RS_ENTRIES; i++)
                    $fdisplay(pipe_out, "%2d |     %d      |     %d      |   %d    |   %d    |    %d    |    %d     |",
                        i, rs_table[i].opa_select, rs_table[i].opb_select, rs_table[i].fu_sel, rs_table[i].op_sel, rs_table[i].alu_func, rs_table[i].mult_func);
                
                $fdisplay(pipe_out, "   | reg1_ready | reg2_ready | rd_mem | wr_mem | cond_branch | uncond_branch | halt | illegal | csr_op | valid |");
                for (int i = 0; i < `N_RS_ENTRIES; i++)
                    $fdisplay(pipe_out, "%2d |     %b      |     %b      |   %b    |   %b    |      %b      |       %b       |  %b   |    %b    |   %b    |   %b   |", 
                        i, rs_table[i].reg1_ready, rs_table[i].reg2_ready, rs_table[i].rd_mem, rs_table[i].wr_mem, rs_table[i].cond_branch, rs_table[i].uncond_branch, rs_table[i].halt, rs_table[i].illegal, rs_table[i].csr_op, rs_table[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "Maptable:");
                $fdisplay(pipe_out, "   | map | done |          | map | done |          | map | done |          | map | done |");
                for (int i = 0; i < (`N_ARCH_REG / 4); i++)
                    $fdisplay(pipe_out, "%2d | %2d  |  %b   |       %2d | %2d  |  %b   |       %2d | %2d  |  %b   |       %2d | %2d  |  %b   |", 
                        i, maptable_packet.map[i], maptable_packet.done[i], (i + 8), maptable_packet.map[i + 8], maptable_packet.done[i + 8], (i + 16), maptable_packet.map[i + 16], maptable_packet.done[i + 16], (i + 24), maptable_packet.map[i + 24], maptable_packet.done[i + 24]);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------FETCH-------------");
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "proc2Imem_addr: | [0]: %d | [1]: %d | [2]: %d |", 
                proc2Imem_addr[0], proc2Imem_addr[1], proc2Imem_addr[2]);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "fetch_packet:");
                $fdisplay(pipe_out, "  |    inst    |   NPC    |    PC    | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d | %d | %x | %x |   %b   |", 
                        i, fetch_packet[i].inst, fetch_packet[i].NPC, fetch_packet[i].PC, fetch_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "fetch_dispatch_packet:");
                $fdisplay(pipe_out, "  |    inst    |   NPC    |    PC    | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d | %d | %x | %x |   %b   |", 
                        i, fetch_dispatch_packet[i].inst, fetch_dispatch_packet[i].NPC, fetch_dispatch_packet[i].PC, fetch_dispatch_packet[i].valid);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------DISPATCH-------------");
            $fdisplay(pipe_out, "");
            
            $fdisplay(pipe_out, "rob_dispatch_packet:");
                $fdisplay(pipe_out, "  | stall | new_entry_idx |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %b   |      %2d       |", 
                        i, rob_dispatch_packet.stall[i], rob_dispatch_packet.new_entry_idx[i]);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "dispatch_fetch_packet: | first_stall_idx: %2d | enable: %b |", 
                dispatch_fetch_packet.first_stall_idx, dispatch_fetch_packet.enable);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "dispatch_rs_packet:");
                $fdisplay(pipe_out, "  |   NPC    |    PC    | reg1_pr_idx | reg2_pr_idx | pr_idx | rob_idx | ar_idx |    inst    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS ; i++)
                    $fdisplay(pipe_out, "%1d | %x | %x |     %2d      |     %2d      |   %2d   |   %2d    |   %2d   | %d |",
                        i, dispatch_rs_packet[i].NPC, dispatch_rs_packet[i].PC, dispatch_rs_packet[i].reg1_pr_idx, dispatch_rs_packet[i].reg2_pr_idx, dispatch_rs_packet[i].pr_idx, dispatch_rs_packet[i].rob_idx, dispatch_rs_packet[i].ar_idx, dispatch_rs_packet[i].inst);
                
                $fdisplay(pipe_out, "  | opa_select |  opb_select | fu_sel | op_sel | alu_func | mult_func |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |     %d      |     %d      |   %d    |   %d    |    %d    |    %d     |",
                        i, dispatch_rs_packet[i].opa_select, dispatch_rs_packet[i].opb_select, dispatch_rs_packet[i].fu_sel, dispatch_rs_packet[i].op_sel, dispatch_rs_packet[i].alu_func, dispatch_rs_packet[i].mult_func);
                
                $fdisplay(pipe_out, "  | reg1_ready | reg2_ready | rd_mem | wr_mem | cond_branch | uncond_branch | halt | illegal | csr_op | enable | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |     %b      |     %b      |   %b    |   %b    |      %b      |       %b       |  %b   |    %b    |   %b    |   %b    |   %b   |", 
                        i, dispatch_rs_packet[i].reg1_ready, dispatch_rs_packet[i].reg2_ready, dispatch_rs_packet[i].rd_mem, dispatch_rs_packet[i].wr_mem, dispatch_rs_packet[i].cond_branch, dispatch_rs_packet[i].uncond_branch, dispatch_rs_packet[i].halt, dispatch_rs_packet[i].illegal, dispatch_rs_packet[i].csr_op, dispatch_rs_packet[i].enable, dispatch_rs_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "dispatch_rob_packet:");
                $fdisplay(pipe_out, "  | t_idx | told_idx | ar_idx | enable |   NPC    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |  %2d   |    %2d    |   %2d   |   %b    | %x |", 
                        i, dispatch_rob_packet[i].t_idx, dispatch_rob_packet[i].told_idx, dispatch_rob_packet[i].ar_idx, dispatch_rob_packet[i].enable, dispatch_rob_packet[i].NPC);
            $fdisplay(pipe_out, "");
            
            $fdisplay(pipe_out, "dispatch_maptable_packet:");
                $fdisplay(pipe_out, "  | pr_idx | ar_idx | enable |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %2d   |   %2d   |   %b    |", 
                        i, dispatch_maptable_packet[i].pr_idx, dispatch_maptable_packet[i].ar_idx, dispatch_maptable_packet[i].enable);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------ISSUE-------------");
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "rs_issue_packet:");
                $fdisplay(pipe_out, "  |   NPC    |    PC    | reg1_pr_idx | reg2_pr_idx | pr_idx | rob_idx | ar_idx |    inst    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS ; i++)
                    $fdisplay(pipe_out, "%1d | %x | %x |     %2d      |     %2d      |   %2d   |   %2d    |   %2d   | %d |",
                        i, rs_issue_packet[i].NPC, rs_issue_packet[i].PC, rs_issue_packet[i].reg1_pr_idx, rs_issue_packet[i].reg2_pr_idx, rs_issue_packet[i].pr_idx, rs_issue_packet[i].rob_idx, rs_issue_packet[i].ar_idx, rs_issue_packet[i].inst);
                
                $fdisplay(pipe_out, "  | opa_select | opb_select | fu_sel | op_sel | rd_mem | wr_mem | cond_branch | uncond_branch | halt | illegal | csr_op | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |     %d      |     %d     |   %d    |   %d    |   %b    |   %b    |      %b      |       %b       |  %b   |    %b    |   %b    |   %b   |",
                        i, rs_issue_packet[i].opa_select, rs_issue_packet[i].opb_select, rs_issue_packet[i].fu_sel, rs_issue_packet[i].op_sel, rs_issue_packet[i].rd_mem, rs_issue_packet[i].wr_mem, rs_issue_packet[i].cond_branch, rs_issue_packet[i].uncond_branch, rs_issue_packet[i].halt, rs_issue_packet[i].illegal, rs_issue_packet[i].csr_op, rs_issue_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "issue_packet:");
                $fdisplay(pipe_out, "  |   NPC    |    PC    | rs1_value  | rs2_value  | pr_idx | rob_idx | ar_idx |    inst    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d | %x | %x | %d | %d |   %2d   |   %2d    |   %2d   | %d |", i, 
                        issue_packet[i].NPC, issue_packet[i].PC, issue_packet[i].rs1_value, issue_packet[i].rs2_value, issue_packet[i].pr_idx, issue_packet[i].rob_idx, issue_packet[i].ar_idx, issue_packet[i].inst);
                
                $fdisplay(pipe_out, "  | opa_select | opb_select | fu_select | op_sel | alu_func | mult_func |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |     %d      |     %d     |     %d     |   %d    |    %d    |    %d     |", 
                        i, issue_packet[i].opa_select, issue_packet[i].opb_select, issue_packet[i].fu_select, issue_packet[i].op_sel, issue_packet[i].alu_func, issue_packet[i].mult_func);
                
                $fdisplay(pipe_out, "  | rd_mem | wr_mem | cond_branch | uncond_branch | halt | illegal | csr_op | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %b    |   %b    |      %b      |       %b       |  %b   |    %b    |   %b    |   %b   |", 
                        i, issue_packet[i].rd_mem, issue_packet[i].wr_mem, issue_packet[i].cond_branch, issue_packet[i].uncond_branch, issue_packet[i].halt, issue_packet[i].illegal, issue_packet[i].csr_op, issue_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "issue_fu_packet:");
                $fdisplay(pipe_out, "  |   NPC    |    PC    | rs1_value  | rs2_value  | pr_idx | rob_idx | ar_idx |    inst    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d | %x | %x | %d | %d |   %2d   |   %2d    |   %2d   | %d |", i, 
                        issue_fu_packet[i].NPC, issue_fu_packet[i].PC, issue_fu_packet[i].rs1_value, issue_fu_packet[i].rs2_value, issue_fu_packet[i].pr_idx, issue_fu_packet[i].rob_idx, issue_fu_packet[i].ar_idx, issue_fu_packet[i].inst);
                
                $fdisplay(pipe_out, "  | opa_select | opb_select | fu_select | op_sel | alu_func | mult_func |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |     %d      |     %d     |     %d     |   %d    |    %d    |    %d     |", 
                        i, issue_fu_packet[i].opa_select, issue_fu_packet[i].opb_select, issue_fu_packet[i].fu_select, issue_fu_packet[i].op_sel, issue_fu_packet[i].alu_func, issue_fu_packet[i].mult_func);
                
                $fdisplay(pipe_out, "  | rd_mem | wr_mem | cond_branch | uncond_branch | halt | illegal | csr_op | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %b    |   %b    |      %b      |       %b       |  %b   |    %b    |   %b    |   %b   |", 
                        i, issue_fu_packet[i].rd_mem, issue_fu_packet[i].wr_mem, issue_fu_packet[i].cond_branch, issue_fu_packet[i].uncond_branch, issue_fu_packet[i].halt, issue_fu_packet[i].illegal, issue_fu_packet[i].csr_op, issue_fu_packet[i].valid);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------EXECUTE-------------");
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "fu_packet:");
                $fdisplay(pipe_out, "  | pr_idx | ar_idx | rob_idx | target_pc  | dest_value | rd_mem | wr_mem | halt | take_branch | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %2d   |   %2d   |   %2d    | %d | %d |   %b    |   %b    |  %b   |      %b      |   %b   |",
                        i, fu_packet[i].pr_idx, fu_packet[i].ar_idx, fu_packet[i].rob_idx, fu_packet[i].target_pc, fu_packet[i].dest_value, fu_packet[i].rd_mem, fu_packet[i].wr_mem, fu_packet[i].halt, fu_packet[i].take_branch, fu_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "fu_rs_packet: | alu_1: %b | alu_2: %b | alu_3: %b | mult_1: %b | mult_2: %b | branch_1: %b |", 
                fu_rs_packet.alu_1, fu_rs_packet.alu_2, fu_rs_packet.alu_3, fu_rs_packet.mult_1, fu_rs_packet.mult_2, fu_rs_packet.branch_1 );
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out,"fu_prf_packet:" );
                $fdisplay(pipe_out, "  | idx |   value    |");
                for (int i = 0; i < 7; i++) 
                    $fdisplay(pipe_out,"%1d | %2d  | %d |",
                        i,  fu_prf_packet[i].idx, fu_prf_packet[i].value);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------COMPLETE-------------");
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out,"complete_rob_packet:");
                $fdisplay(pipe_out,"  | rob_idx | dest_value | complete |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |   %2d    | %d |    %b     |", 
                        i, complete_rob_packet[i].rob_idx, complete_rob_packet[i].dest_value, complete_rob_packet[i].complete);
            $fdisplay(pipe_out, "");
            
            $fdisplay(pipe_out, "cdb_packet: | t_idx[0]:%1d | t_idx[1]:%1d | t_idx[2]:%1d |", 
                cdb_packet.t_idx[0], cdb_packet.t_idx[1], cdb_packet.t_idx[2]);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");

        $fdisplay(pipe_out, "-------------RETIRE-------------");
            $fdisplay(pipe_out, "");
            
            $fdisplay(pipe_out, "rob_retire_packet:");
                $fdisplay(pipe_out, "  | t_idx | told_idx | ar_idx | halt | precise | complete | target_pc  | dest_value |   NPC    |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |  %2d   |    %2d    |   %2d   |  %b   |    %b    |    %b     | %d | %d | %x |", 
                        i, rob_retire_packet[i].t_idx, rob_retire_packet[i].told_idx,rob_retire_packet[i].ar_idx,rob_retire_packet[i].halt, rob_retire_packet[i].precise_state_enable, rob_retire_packet[i].complete, rob_retire_packet[i].target_pc, rob_retire_packet[i].dest_value ,rob_retire_packet[i].NPC);
            $fdisplay(pipe_out, "");
            
            $fdisplay(pipe_out, "retire_packet:");
                $fdisplay(pipe_out, "  | t_idx | ar_idx |   NPC    | complete |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |  %2d   |   %2d   | %x |    %b     |",
                        i, retire_packet[i].t_idx, retire_packet[i].ar_idx, retire_packet[i].NPC, retire_packet[i].complete);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "retire_freelist_packet:");
                $fdisplay(pipe_out, "  | told_idx | valid |");
                for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                    $fdisplay(pipe_out, "%1d |    %2d    |   %b   |", 
                        i, retire_freelist_packet[i].told_idx, retire_freelist_packet[i].valid);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "retire_wfi_halt: %b", retire_wfi_halt);
            $fdisplay(pipe_out, "");

            $fdisplay(pipe_out, "halt: %b", halt);
            $fdisplay(pipe_out, "");
        $fdisplay(pipe_out, "");
    endfunction

    always @(negedge clock) begin
        if (~reset) begin
            $fdisplay(pipe_out, "");
            $fdisplay(pipe_out,"@@ Cycle Count:%d ---------------------------------------------------------", clock_count);
            $fdisplay(pipe_out, "");
            dump_output();
        end
        else begin
            $fdisplay(pipe_out,"@@ Resetting --------------------------------------------------------------");
            $fdisplay(pipe_out, "");
        end
    end


    // Task to display # of elapsed clock edges
    task show_clk_count;
        real cpi;

        begin
            cpi = (clock_count + 1.0) / instr_count;
            $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
                clock_count+1, instr_count, cpi);
            $display("@@  %4.2f ns total time to execute\n@@\n",
                clock_count*`VERILOG_CLOCK_PERIOD);
        end
    endtask  // task show_clk_count


    // Count the number of posedges and number of instructions completed
    // till simulation ends
    always @(posedge clock) begin
        if(reset) begin
            clock_count <= `SD 0;
            //instr_count <= `SD 0;
        end else begin
            clock_count <= `SD (clock_count + 1);
            //instr_count <= `SD (instr_count + ROB_entries_retired);
        end
    end

    always @(negedge clock) begin
        if(reset) begin
            //clock_count <= `SD 0;
            instr_count <= `SD 0;
        end else begin
            //clock_count <= `SD (clock_count + 1);
            instr_count <= `SD (instr_count + ROB_entries_retired);
        end
    end


    always begin
        #(`VERILOG_CLOCK_PERIOD/2.0); //clock "interval" ... AKA 1/2 the period
        clock=~clock;
    end

    // ignore superscalar
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            Imem2proc_data[i] = tb_mem[fetch_PC_out[i][`XLEN-1:3]];
    end

    always @(negedge clock) begin
        if(reset) begin
            $display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
                $realtime);
            debug_counter <= 0;
        end else begin
            `SD;
            `SD;
    

            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if(retire_packet[i].complete) begin
                    if(retire_packet[i].ar_idx != `ZERO_REG)  begin
                        $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
                            retire_packet[i].NPC-4 , retire_packet[i].ar_idx, retire_packet[i].dest_value);
                        // if (br_recover_enable)
                        //     $fdisplay(wb_fileno, "branch taken");
                    end
                    else begin
                        $fdisplay(wb_fileno, "PC=%x, ---",retire_packet[i].NPC-4);
                    end
                end
            end



            // deal with any halting conditions
            if(halt == 1'b1) begin
                show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);
                $display("@@  %t : System halted\n@@", $realtime);
                $display("@@@ System halted on WFI instruction");
                $display("@@@\n@@");
                show_clk_count;
                $fclose(wb_fileno);
                #1
                $fclose(pipe_out);
                $finish;
            end
            debug_counter <= debug_counter + 1;
        end  // if(reset)
    end

    // Show contents of a range of Unified Memory, in both hex and decimal
    task show_mem_with_decimal;
        input [31:0] start_addr;
        input [31:0] end_addr;
        int showing_data;
        begin
            $display("@@@");
            showing_data=0;
            for(int k=start_addr;k<=end_addr; k=k+1)
                if (tb_mem[k] != 0) begin
                    $display("@@@ mem[%5d] = %x : %0d", k*8, tb_mem[k],
                        tb_mem[k]);
                    showing_data=1;
                end else if(showing_data!=0) begin
                    $display("@@@");
                    showing_data=0;
                end
            $display("@@@");
        end
    endtask  // task show_mem_with_decimal


    initial begin
        $dumpvars;
        $display("STARTING TESTBENCH!\n");
        $readmemh("./program.mem", tb_mem);
        wb_fileno = $fopen("./writeback.out","w");
        pipe_out = $fopen("./pipeline.out","w");
        //$displayh("%p",tb_mem[1]);
        enable = 1;
        clock = 1;

        reset = 1'b0;
        // Pulse the reset signal
        $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
        reset = 1'b1;
        @(posedge clock);
        @(posedge clock);
        `SD;
        //dump_output();
        // This reset is at an odd time to avoid the pos & neg clock edges
        reset = 1'b0;
        $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);

        #10000
        $display("@@  %t  Can't STOP!!!!!!!!!!!!!!!!!......\n@@\n@@", $realtime);
	    $finish;

    end


endmodule
