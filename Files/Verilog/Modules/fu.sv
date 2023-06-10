//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :  fu.sv  		                                        //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the 		// 
//                 result, and compute the condition for branches, and  //
//                 pass all the results down the pipeline. MWB          // 
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module fu (
	input 											   	clock,
	input 											   	reset,
	input  ISSUE_FU_PACKET 	  	[`SUPERSCALAR_WAYS-1:0] fu_issue_in,

	output FU_COMPLETE_PACKET 	[`SUPERSCALAR_WAYS-1:0] fu_complete_out,
	output FU_RS_PACKET 							   	fu_rs_out,
	output FU_PRF_PACKET 	  	[6:0] 				   	fu_prf_out

  `ifdef TEST_MODE 
  , output ISSUE_FU_PACKET 						   		fu_issue_in_mult1_check
  , output ISSUE_FU_PACKET 						   		fu_issue_in_br_check
  , output logic 				[`XLEN-1:0] 		   	mult1_a_check
  , output logic 				[`XLEN-1:0] 		   	mult1_b_check
  , output logic 				[`XLEN-1:0] 		   	mult1_result_check
  , output logic 				[4:0] 				   	mult1_finish_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count0_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count1_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count2_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count3_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count4_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count5_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count6_check
  , output logic 				[`N_FU_UNITS_BITS-1:0] 	count7_check
  , output logic 									   	pc21_compare_check
  , output logic 									   	pc20_compare_check
  , output logic 									   	pc10_compare_check
  , output logic 									   	br_done_check
  , output logic 									   	mult1_done_check
  , output logic 									   	mult2_done_check
  , output logic 									  	alu1_done_check
  , output logic 									   	alu2_done_check
  , output logic 									   	alu3_done_check
  , output logic 									   	alu2_reg_has_value_check
  , output logic 									   	alu2_reg_has_value_pre_check
  , output FU_COMPLETE_PACKET 					   		alu2_reg_packet_check
  , output FU_COMPLETE_PACKET 					   		fu_complete_out_br_check
  , output FU_COMPLETE_PACKET 					   		fu_complete_out_alu2_check
  , output logic 			 	[1:0] 				   	if_state_check
  `endif
);
	FU_COMPLETE_PACKET [2:0] fu_complete_out_unorder;

	logic [7:0] want_to_complete;  // LS_1 = 0, LS_2 = 1, ALU_1 = 2, ALU_2 = 3, ALU_3 = 4, MULT_1 = 5, MULT_2 = 6,
	logic [2:0] count0, count1, count2, count3, count4, count5, count6, count7;
	logic br_done, ls1_done, ls2_done, mult1_done, mult2_done, alu1_done, alu2_done, alu3_done;
	logic pc21_compare, pc20_compare, pc10_compare;

	ISSUE_FU_PACKET fu_issue_in_ls1,   fu_issue_in_ls2;
	ISSUE_FU_PACKET fu_issue_in_alu1,  fu_issue_in_alu2,  fu_issue_in_alu3;
	ISSUE_FU_PACKET fu_issue_in_mult1, fu_issue_in_mult2;
	ISSUE_FU_PACKET fu_issue_in_br;

	FU_COMPLETE_PACKET fu_complete_out_ls1,   fu_complete_out_ls2;
	FU_COMPLETE_PACKET fu_complete_out_alu1,  fu_complete_out_alu2,  fu_complete_out_alu3;
	FU_COMPLETE_PACKET fu_complete_out_mult1, fu_complete_out_mult2;
	FU_COMPLETE_PACKET fu_complete_out_br;

	FU_COMPLETE_PACKET alu1_reg_packet,  alu2_reg_packet,  alu3_reg_packet;
	FU_COMPLETE_PACKET mult1_reg_packet, mult2_reg_packet;

	FU_COMPLETE_PACKET fu_complete_out_alu1_reg, fu_complete_out_alu2_reg, fu_complete_out_alu3_reg;
	FU_COMPLETE_PACKET fu_complete_out_br_reg;

	logic alu1_reg_has_value,  alu2_reg_has_value,  alu3_reg_has_value;
	logic mult1_reg_has_value, mult2_reg_has_value;

	logic alu1_reg_has_value_pre,  alu2_reg_has_value_pre,  alu3_reg_has_value_pre;
	logic mult1_reg_has_value_pre, mult2_reg_has_value_pre;

	logic want_to_complete_alu1_reg, want_to_complete_alu2_reg, want_to_complete_alu3_reg;
	logic want_to_complete_br_reg;

	logic [`XLEN-1:0] mult1_a, mult1_b, mult2_a, mult2_b;
	logic [`XLEN-1:0] mult1_result, mult2_result;
	logic [4:0] 	  mult1_finish, mult2_finish;
	logic 			  mult1_start, mult2_start;

`ifdef TEST_MODE
	assign fu_issue_in_mult1_check = fu_issue_in_mult1;
	assign mult1_a_check = mult1_a;
	assign mult1_b_check = mult1_b;
	assign count0_check = count0;
	assign count1_check = count1;
	assign count2_check = count2;
	assign count3_check = count3;
	assign count4_check = count4;
	assign count5_check = count5;
	assign count6_check = count6;
	assign count7_check = count7;
	assign pc21_compare_check = pc21_compare;
	assign pc20_compare_check = pc20_compare;
	assign pc10_compare_check = pc10_compare;
	assign br_done_check = br_done;
	assign mult1_done_check = mult1_done;
	assign mult2_done_check = mult2_done;
	assign mult1_result_check = fu_complete_out_mult1.dest_value;
	assign mult1_finish_check = mult1_finish;
	assign alu1_done_check = alu1_done;
	assign alu2_done_check = alu2_done;
	assign alu3_done_check = alu3_done;
	assign alu2_reg_has_value_check = alu2_reg_has_value;
	assign alu2_reg_has_value_pre_check = alu2_reg_has_value_pre;
	assign alu2_reg_packet_check = alu2_reg_packet;
	assign fu_complete_out_br_check = fu_complete_out_br;
	assign fu_complete_out_alu2_check = fu_complete_out_alu2;
	assign fu_issue_in_br_check = fu_issue_in_br;
`endif

	always_comb begin
		fu_issue_in_alu1  = '0;
		fu_issue_in_alu2  = '0;
		fu_issue_in_alu3  = '0;
		fu_issue_in_mult1 = '0;
		fu_issue_in_mult2 = '0;
		fu_issue_in_br    = '0;

		mult1_a 	= '0;
		mult1_b 	= '0;
		mult2_a 	= '0;
		mult2_b 	= '0;
		mult1_start = '0;
		mult2_start = '0;

		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			case (fu_issue_in[i].fu_select)
				//LS_1: 
				//LS_2:
				ALU_1:   fu_issue_in_alu1 = fu_issue_in[i];
				ALU_2:   fu_issue_in_alu2 = fu_issue_in[i];
				ALU_3:   fu_issue_in_alu3 = fu_issue_in[i];
				MULT_1:  begin
					mult1_a			  = fu_issue_in[i].rs1_value;
					mult1_b			  = fu_issue_in[i].rs2_value;
					mult1_start		  = `TRUE;
					fu_issue_in_mult1 = fu_issue_in[i];
				end
				MULT_2:  begin
					mult2_a			  = fu_issue_in[i].rs1_value;
					mult2_b			  = fu_issue_in[i].rs2_value;
					mult2_start 	  = `TRUE;
					fu_issue_in_mult2 = fu_issue_in[i];
				end
				BRANCH:  fu_issue_in_br = fu_issue_in[i];
			endcase  // case (fu_issue_in[i].fu_select)
		end  // for each instruction
	end  // always_comb  // fu_issue_in

	fu_alu alu1 (
		.fu_issue_in(fu_issue_in_alu1),
		.want_to_complete(want_to_complete[2]),
		.fu_packet_out(fu_complete_out_alu1)
	);

	fu_alu alu2 (
		.fu_issue_in(fu_issue_in_alu2),
		.want_to_complete(want_to_complete[3]),
		.fu_packet_out(fu_complete_out_alu2)
	);

	fu_alu alu3 (
		.fu_issue_in(fu_issue_in_alu3),
		.want_to_complete(want_to_complete[4]),
		.fu_packet_out(fu_complete_out_alu3)
	);

	mult mult1 (
		.clock(clock), 
		.reset(reset),
		.mcand(mult1_a),
		.mplier(mult1_b),
		.sign(2'd0),
		.start(mult1_start),
		.mult_func(fu_issue_in_mult1.mult_func),
		.fu_issue_in(fu_issue_in_mult1),
		.done(mult1_finish),
		.fu_complete_out(fu_complete_out_mult1)
	);

	mult mult2 (
		.clock(clock), 
		.reset(reset),
		.mcand(mult2_a),
		.mplier(mult2_b),
		.sign(2'd0),
		.start(mult2_start),
		.mult_func(fu_issue_in_mult2.mult_func),
		.fu_issue_in(fu_issue_in_mult2),
		.done(mult2_finish),
		.fu_complete_out(fu_complete_out_mult2)
	);

	fu_alu br (
		.fu_issue_in(fu_issue_in_br),
		.want_to_complete(want_to_complete[7]),
		.fu_packet_out(fu_complete_out_br)
	);

	assign ls1_done   = `FALSE;
	assign ls2_done   = `FALSE;
	assign alu1_done  = (want_to_complete_alu1_reg | alu1_reg_has_value_pre);
	assign alu2_done  = (want_to_complete_alu2_reg | alu2_reg_has_value_pre);
	assign alu3_done  = (want_to_complete_alu3_reg | alu3_reg_has_value_pre);
	assign mult1_done = (mult1_finish[4] | mult1_reg_has_value_pre);
	assign mult2_done = (mult2_finish[4] | mult2_reg_has_value_pre);
	assign br_done    = want_to_complete_br_reg;

	always_comb begin
		fu_prf_out = '0;

		if (alu1_done) begin
			fu_prf_out[2].idx   = fu_complete_out_alu1_reg.pr_idx;
			fu_prf_out[2].value = fu_complete_out_alu1_reg.dest_value;
		end  // if (alu1_done)

		if (alu2_done) begin
			fu_prf_out[3].idx   = fu_complete_out_alu2_reg.pr_idx;
			fu_prf_out[3].value = fu_complete_out_alu2_reg.dest_value;
		end  // if (alu2_done)

		if (alu3_done) begin
			fu_prf_out[4].idx = fu_complete_out_alu3_reg.pr_idx;
			fu_prf_out[4].value = fu_complete_out_alu3_reg.dest_value;
		end  // if (alu3_done)

		if (mult1_done) begin
			fu_prf_out[5].idx = fu_complete_out_mult1.pr_idx;
			fu_prf_out[5].value = fu_complete_out_mult1.dest_value;
		end  // if (mult1_done)

		if (mult2_done) begin
			fu_prf_out[6].idx = fu_complete_out_mult2.pr_idx;
			fu_prf_out[6].value = fu_complete_out_mult2.dest_value;
		end  // if (mult2_done)
	end  // always_comb  // fu_prf_out

	always_comb begin
		count0 = br_done;
		count1 = count0 + ls1_done;
		count2 = count1 + ls2_done;
		count3 = count2 + mult1_done;
		count4 = count3 + mult2_done;
		count5 = count4 + alu1_done;
		count6 = count5 + alu2_done;
		count7 = count6 + alu3_done;
	end  // always_comb  // count

	always_comb begin
		fu_rs_out = '0;

		if (((count3 > `SUPERSCALAR_WAYS) & (mult1_done)) | (|mult1_finish[3:0]))
			fu_rs_out.mult_1 = `TRUE;

		if (((count4 > `SUPERSCALAR_WAYS) & (mult2_done)) | (|mult2_finish[3:0]))
			fu_rs_out.mult_2 = `TRUE;

		if ((count5 > `SUPERSCALAR_WAYS) & (alu1_done))
			fu_rs_out.alu_1 = `TRUE;

		if ((count6 > `SUPERSCALAR_WAYS) & (alu2_done))
			fu_rs_out.alu_2 = `TRUE;

		if ((count7 > `SUPERSCALAR_WAYS) & (alu3_done))
			fu_rs_out.alu_3 = `TRUE;
	end  // always_comb  // fu_rs_out

	always_comb begin
		mult1_reg_has_value = ((count3 > `SUPERSCALAR_WAYS) & (mult1_done)) ? `TRUE : `FALSE;
		mult2_reg_has_value = ((count4 > `SUPERSCALAR_WAYS) & (mult2_done)) ? `TRUE : `FALSE;
		alu1_reg_has_value  = ((count5 > `SUPERSCALAR_WAYS) & (alu1_done))  ? `TRUE : `FALSE;
		alu2_reg_has_value  = ((count6 > `SUPERSCALAR_WAYS) & (alu2_done))  ? `TRUE : `FALSE;
		alu3_reg_has_value  = ((count7 > `SUPERSCALAR_WAYS) & (alu3_done))  ? `TRUE : `FALSE;
	end  // always_comb  // reg_has_value

	always_ff @(posedge clock) begin
		if (reset) begin
			mult1_reg_packet		  <= `SD '0;
			mult2_reg_packet		  <= `SD '0;
			alu1_reg_packet			  <= `SD '0;
			alu2_reg_packet			  <= `SD '0;
			alu3_reg_packet			  <= `SD '0;
			mult1_reg_has_value_pre	  <= `SD `FALSE;
			mult2_reg_has_value_pre	  <= `SD `FALSE;
			alu1_reg_has_value_pre	  <= `SD `FALSE;
			alu2_reg_has_value_pre	  <= `SD `FALSE;
			alu3_reg_has_value_pre	  <= `SD `FALSE;
			want_to_complete_br_reg	  <= `SD `FALSE;
			want_to_complete_alu1_reg <= `SD `FALSE;
			want_to_complete_alu2_reg <= `SD `FALSE;
			want_to_complete_alu3_reg <= `SD `FALSE;
			fu_complete_out_br_reg 	  <= `SD '0;
			fu_complete_out_alu1_reg  <= `SD '0;
			fu_complete_out_alu2_reg  <= `SD '0;
			fu_complete_out_alu3_reg  <= `SD '0;

		  `ifdef TEST_MODE
			if_state_check <= `SD '0;
		  `endif
		end  // if (reset)
		else begin
			mult1_reg_has_value_pre	  <= `SD mult1_reg_has_value;
			mult2_reg_has_value_pre	  <= `SD mult2_reg_has_value;
			alu1_reg_has_value_pre	  <= `SD alu1_reg_has_value;
			alu2_reg_has_value_pre	  <= `SD alu2_reg_has_value;
			alu3_reg_has_value_pre	  <= `SD alu3_reg_has_value;
			want_to_complete_br_reg	  <= `SD want_to_complete[7];
			want_to_complete_alu1_reg <= `SD want_to_complete[2];
			want_to_complete_alu2_reg <= `SD want_to_complete[3];
			want_to_complete_alu3_reg <= `SD want_to_complete[4];
			fu_complete_out_br_reg	  <= `SD fu_complete_out_br;
			fu_complete_out_alu1_reg  <= `SD fu_complete_out_alu1;
			fu_complete_out_alu2_reg  <= `SD fu_complete_out_alu2;
			fu_complete_out_alu3_reg  <= `SD fu_complete_out_alu3;

			if ((count3 > `SUPERSCALAR_WAYS) & mult1_done) begin
				if (mult1_reg_has_value_pre) mult1_reg_packet <= `SD mult1_reg_packet;
				else						 mult1_reg_packet <= `SD fu_complete_out_mult1;
			end  // if ((count3 > `SUPERSCALAR_WAYS) & mult1_done)
			else mult1_reg_packet <= `SD '0;

			if ((count4 > `SUPERSCALAR_WAYS) & mult2_done) begin
				if (mult2_reg_has_value_pre) mult2_reg_packet <= `SD mult2_reg_packet;
				else						 mult2_reg_packet <= `SD fu_complete_out_mult2;
			end  // if ((count4 > `SUPERSCALAR_WAYS) & mult2_done)
			else mult2_reg_packet <= `SD '0;

			if ((count5 > `SUPERSCALAR_WAYS) & alu1_done) begin
				if (alu1_reg_has_value_pre) alu1_reg_packet <= `SD alu1_reg_packet;
				else						alu1_reg_packet <= `SD fu_complete_out_alu1_reg;
			end  // if ((count5 > `SUPERSCALAR_WAYS) & alu1_done)
			else alu1_reg_packet <= `SD '0;

			if ((count6 > `SUPERSCALAR_WAYS) & alu2_done) begin
				if (alu2_reg_has_value_pre) begin
					alu2_reg_packet <= `SD alu2_reg_packet;
				  `ifdef TEST_MODE	
				  	if_state_check  <= `SD 2'd1;  
				  `endif
				end  // if (alu2_reg_has_value_pre)
				else begin
					alu2_reg_packet <= `SD fu_complete_out_alu2_reg;
				  `ifdef TEST_MODE	
				  	if_state_check  <= `SD 2'd2;  
				  `endif
				end  // if (~alu2_reg_has_value_pre)
			end  // if ((count6 > `SUPERSCALAR_WAYS) & alu2_done)
			else begin
				alu2_reg_packet <= `SD '0;
			  `ifdef TEST_MODE	
			  	if_state_check  <= `SD 2'd3;  
			  `endif
			end  // if ((count6 <= `SUPERSCALAR_WAYS) | ~alu2_done)

			if ((count7 > `SUPERSCALAR_WAYS) & alu3_done) begin
				if (alu3_reg_has_value_pre) alu3_reg_packet <= `SD alu3_reg_packet;
				else 						alu3_reg_packet <= `SD fu_complete_out_alu3_reg;
			end  // if ((count7 > `SUPERSCALAR_WAYS) & alu3_done)
			else alu3_reg_packet <= `SD '0;
		end  // if (~reset)
	end  // always_ff @(posedge clock)

	always_comb begin
		fu_complete_out_unorder = '0;

		if (count7 == 2) begin
			if		((count0 == 3'd1) & br_done) fu_complete_out_unorder[0] = fu_complete_out_br_reg;
			else if ((count1 == 3'd1) & ls1_done) fu_complete_out_unorder[0] = fu_complete_out_ls1;
			else if ((count2 == 3'd1) & ls2_done) fu_complete_out_unorder[0] = fu_complete_out_ls2;
			else if ((count3 == 3'd1) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[0] = mult1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult1;
			end
			else if ((count4 == 3'd1) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[0] = mult2_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult2;
			end
			else if ((count5 == 3'd1) & alu1_done) begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[0] = alu1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu1_reg;
			end
			else begin
				if (alu2_reg_has_value_pre) fu_complete_out_unorder[0] = alu2_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu2_reg;
			end


			if 		((count1 == 3'd2) & ls1_done) fu_complete_out_unorder[1] = fu_complete_out_ls1;
			else if ((count2 == 3'd2) & ls2_done) fu_complete_out_unorder[1] = fu_complete_out_ls2;
			else if ((count3 == 3'd2) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[1] = mult1_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_mult1;
			end
			else if ((count4 == 3'd2) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[1] = mult2_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_mult2;
			end
			else if ((count5 == 3'd2) & alu1_done) begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[1] = alu1_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_alu1_reg;
			end
			else if ((count6 == 3'd2) & alu2_done) begin
				if (alu2_reg_has_value_pre) fu_complete_out_unorder[1] = alu2_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_alu2_reg;
			end
			else begin
				if (alu3_reg_has_value_pre) fu_complete_out_unorder[1] = alu3_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_alu3_reg;
			end
		end

		else if(count7 == 1) begin
			if		((count0 == 3'd1) & br_done) fu_complete_out_unorder[0] = fu_complete_out_br_reg;
			else if ((count1 == 3'd1) & ls1_done) fu_complete_out_unorder[0] = fu_complete_out_ls1;
			else if ((count2 == 3'd1) & ls2_done) fu_complete_out_unorder[0] = fu_complete_out_ls2;
			else if ((count3 == 3'd1) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[0] = mult1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult1;
			end
			else if ((count4 == 3'd1) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[0] = mult2_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult2;
			end
			else if ((count5 == 3'd1) & alu1_done) begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[0] = alu1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu1_reg;
			end
			else if ((count6 == 3'd1) & alu2_done) begin
				if (alu2_reg_has_value_pre) fu_complete_out_unorder[0] = alu2_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu2_reg;
			end
			else begin
				if (alu3_reg_has_value_pre) fu_complete_out_unorder[0] = alu3_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu3_reg;
			end

		end
		else if (count7 != 0) begin
			if		((count0 == 3'd1) & br_done) fu_complete_out_unorder[0] = fu_complete_out_br_reg;
			else if ((count1 == 3'd1) & ls1_done) fu_complete_out_unorder[0] = fu_complete_out_ls1;
			else if ((count2 == 3'd1) & ls2_done) fu_complete_out_unorder[0] = fu_complete_out_ls2;
			else if ((count3 == 3'd1) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[0] = mult1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult1;
			end
			else if ((count4 == 3'd1) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[0] = mult2_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_mult2;
			end
			else begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[0] = alu1_reg_packet;
				else fu_complete_out_unorder[0] = fu_complete_out_alu1_reg;
			end


			if 		((count1 == 3'd2) & ls1_done) fu_complete_out_unorder[1] = fu_complete_out_ls1;
			else if ((count2 == 3'd2) & ls2_done) fu_complete_out_unorder[1] = fu_complete_out_ls2;
			else if ((count3 == 3'd2) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[1] = mult1_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_mult1;
			end
			else if ((count4 == 3'd2) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[1] = mult2_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_mult2;
			end
			else if ((count5 == 3'd2) & alu1_done) begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[1] = alu1_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_alu1_reg;
			end
			else begin
				if (alu2_reg_has_value_pre) fu_complete_out_unorder[1] = alu2_reg_packet;
				else fu_complete_out_unorder[1] = fu_complete_out_alu2_reg;
			end


			if 		((count2 == `SUPERSCALAR_WAYS) & ls2_done) fu_complete_out_unorder[2] = fu_complete_out_ls2;
			else if ((count3 == `SUPERSCALAR_WAYS) & mult1_done) begin
				if (mult1_reg_has_value_pre) fu_complete_out_unorder[2] = mult1_reg_packet;
				else fu_complete_out_unorder[2] = fu_complete_out_mult1;
			end
			else if ((count4 == `SUPERSCALAR_WAYS) & mult2_done) begin
				if (mult2_reg_has_value_pre) fu_complete_out_unorder[2] = mult2_reg_packet;
				else fu_complete_out_unorder[2] = fu_complete_out_mult2;
			end
			else if ((count5 == `SUPERSCALAR_WAYS) & alu1_done) begin
				if (alu1_reg_has_value_pre) fu_complete_out_unorder[2] = alu1_reg_packet;
				else fu_complete_out_unorder[2] = fu_complete_out_alu1_reg;
			end
			else if ((count6 == `SUPERSCALAR_WAYS) & alu2_done) begin
				if (alu2_reg_has_value_pre) fu_complete_out_unorder[2] = alu2_reg_packet;
				else fu_complete_out_unorder[2] = fu_complete_out_alu2_reg;
			end
			else begin
				if (alu3_reg_has_value_pre) fu_complete_out_unorder[2] = alu3_reg_packet;
				else fu_complete_out_unorder[2] = fu_complete_out_alu3_reg;
			end
		end
	end

	assign pc21_compare = (fu_complete_out_unorder[2].rob_idx > fu_complete_out_unorder[1].rob_idx) ? `TRUE : `FALSE;
	assign pc20_compare = (fu_complete_out_unorder[2].rob_idx > fu_complete_out_unorder[0].rob_idx) ? `TRUE : `FALSE;
	assign pc10_compare = (fu_complete_out_unorder[1].rob_idx > fu_complete_out_unorder[0].rob_idx) ? `TRUE : `FALSE;

	always_comb begin
		fu_complete_out = '0;
		
		if(count7 == 2) begin
			if(pc10_compare) begin
				fu_complete_out[2] = fu_complete_out_unorder[2];
				fu_complete_out[1] = fu_complete_out_unorder[1];
				fu_complete_out[0] = fu_complete_out_unorder[0];
			end
			else begin
				fu_complete_out[2] = fu_complete_out_unorder[2];
				fu_complete_out[1] = fu_complete_out_unorder[0];
				fu_complete_out[0] = fu_complete_out_unorder[1];
			end
		end
		else if(count7 == 1) begin
			fu_complete_out[2] = fu_complete_out_unorder[2];
			fu_complete_out[1] = fu_complete_out_unorder[1];
			fu_complete_out[0] = fu_complete_out_unorder[0];
		end
		else begin
			case({pc21_compare, pc20_compare, pc10_compare})
				3'b111: begin
					fu_complete_out[2] = fu_complete_out_unorder[2];
					fu_complete_out[1] = fu_complete_out_unorder[1];
					fu_complete_out[0] = fu_complete_out_unorder[0];
				end
				3'b110: begin
					fu_complete_out[2] = fu_complete_out_unorder[2];
					fu_complete_out[1] = fu_complete_out_unorder[0];
					fu_complete_out[0] = fu_complete_out_unorder[1];
				end
				3'b011: begin
					fu_complete_out[2] = fu_complete_out_unorder[1];
					fu_complete_out[1] = fu_complete_out_unorder[2];
					fu_complete_out[0] = fu_complete_out_unorder[0];
				end
				3'b100: begin
					fu_complete_out[2] = fu_complete_out_unorder[0];
					fu_complete_out[1] = fu_complete_out_unorder[2];
					fu_complete_out[0] = fu_complete_out_unorder[1];
				end
				3'b001: begin
					fu_complete_out[2] = fu_complete_out_unorder[1];
					fu_complete_out[1] = fu_complete_out_unorder[0];
					fu_complete_out[0] = fu_complete_out_unorder[2];
				end
				3'b000: begin
					fu_complete_out[2] = fu_complete_out_unorder[0];
					fu_complete_out[1] = fu_complete_out_unorder[1];
					fu_complete_out[0] = fu_complete_out_unorder[2];
				end
				default: begin
					fu_complete_out[2] = fu_complete_out_unorder[2];
					fu_complete_out[1] = fu_complete_out_unorder[1];
					fu_complete_out[0] = fu_complete_out_unorder[0];
				end

			endcase
		end
	end
endmodule  // fu