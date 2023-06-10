//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :  mult.sv                                              //
//                                                                      //
//  Description :  multiplier submodule of the fu module;               //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module mult #(parameter NUM_STAGE = 4) (
	input 									clock, 
	input 									reset,
	input 									start,
	input 					  [`XLEN-1:0] 	mcand,
	input 					  [`XLEN-1:0] 	mplier,
	input 					  [1:0] 		sign,
	input  MULT_FUNC 						mult_func,
	input  ISSUE_FU_PACKET 					fu_issue_in,

	output logic 			  [NUM_STAGE:0] done,
	output FU_COMPLETE_PACKET 				fu_complete_out
);
	ISSUE_FU_PACKET 				   fu_issue_in_reg;
	MULT_FUNC 						   mult_func_reg;
  	logic [(`XLEN*2)-1:0] 			   mcand_out;
  	logic [(`XLEN*2)-1:0] 			   mplier_out;
  	logic [(`XLEN*2)-1:0] 			   mcand_in;
  	logic [(`XLEN*2)-1:0] 			   mplier_in;
  	logic [NUM_STAGE:0][(`XLEN*2)-1:0] internal_products;
  	logic [NUM_STAGE:0][(`XLEN*2)-1:0] internal_mcands;
  	logic [NUM_STAGE:0][(`XLEN*2)-1:0] internal_mpliers;
  	logic [NUM_STAGE:0] 			   internal_dones;
	logic [`XLEN-1:0] 				   product;

	assign mcand_in  			= sign[0] ? { {`XLEN{mcand[`XLEN - 1]}}, mcand }   : 
								  { {`XLEN{1'b0}}, mcand };
	assign mplier_in 			= sign[1] ? { {`XLEN{mplier[`XLEN - 1]}}, mplier } : 
								  { {`XLEN{1'b0}}, mplier };
	assign internal_mcands[0]   = mcand_in;
	assign internal_mpliers[0]  = mplier_in;
	assign internal_products[0] = 0;
	assign internal_dones[0]    = start;
	assign done    				= internal_dones;

	assign fu_complete_out.rd_mem	   = fu_issue_in_reg.rd_mem;
	assign fu_complete_out.wr_mem	   = fu_issue_in_reg.wr_mem;
	assign fu_complete_out.halt	  	   = fu_issue_in_reg.halt;
	assign fu_complete_out.valid	   = done[NUM_STAGE];
	assign fu_complete_out.pr_idx	   = fu_issue_in_reg.pr_idx;
	assign fu_complete_out.ar_idx	   = fu_issue_in_reg.ar_idx;
	assign fu_complete_out.rob_idx 	   = fu_issue_in_reg.rob_idx;
	assign fu_complete_out.dest_value  = product;
	assign fu_complete_out.take_branch = `FALSE;
	assign fu_complete_out.target_pc   = 0;

	always_ff @(posedge clock) begin
		if (reset) begin
			mult_func_reg   <= `SD ALU_MUL;
			fu_issue_in_reg <= `SD ALU_MUL;
		end  // if (reset)
		else if (start) begin
			mult_func_reg   <= `SD mult_func;
			fu_issue_in_reg <= `SD fu_issue_in;
		end  // if (~reset & start)
		else begin 
			mult_func_reg   <= `SD mult_func_reg;
			fu_issue_in_reg <= `SD fu_issue_in_reg;
		end  // if (~reset & ~start)
	end  // always_ff @(posedge clock)

	always_comb begin
		case (mult_func_reg)
			ALU_MUL:     product = internal_products[NUM_STAGE][`XLEN-1:0];
			ALU_MULH:    product = internal_products[NUM_STAGE][(2*`XLEN)-1:`XLEN];
			ALU_MULHSU:  product = internal_products[NUM_STAGE][(2*`XLEN)-1:`XLEN];
			ALU_MULHU:   product = internal_products[NUM_STAGE][(2*`XLEN)-1:`XLEN];
			default:	 product = 0;
		endcase  // case (mult_func_reg)
	end  // always_comb  // product
  
	genvar i; generate
		for (i = 0; i < NUM_STAGE; i++) begin : mstage
			mult_stage #(.NUM_STAGE(NUM_STAGE)) mult_stage_0 (
				.clock(clock),
				.reset(reset),
				.product_in(internal_products[i]),
				.mplier_in(internal_mpliers[i]),
				.mcand_in(internal_mcands[i]), 
				.start(internal_dones[i]),
				.product_out(internal_products[i + 1]),
				.mplier_out(internal_mpliers[i + 1]),
				.mcand_out(internal_mcands[i + 1]),
				.done(internal_dones[i + 1])
			);
		end  // for each stage
	endgenerate  // generate mstage
endmodule  // mult