//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :  mult_stage.sv                                        //
//                                                                      //
//  Description :  one stage of the fu multiplier;                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module mult_stage #(parameter NUM_STAGE = 4) (
	input 						 clock, 
	input 						 reset, 
	input 						 start,
	input 		 [(`XLEN*2)-1:0] product_in,
	input 		 [(`XLEN*2)-1:0] mplier_in,
	input 		 [(`XLEN*2)-1:0] mcand_in,

	output logic 				 done,
	output logic [(`XLEN*2)-1:0] product_out,
	output logic [(`XLEN*2)-1:0] mplier_out,
	output logic [(`XLEN*2)-1:0] mcand_out
);
	parameter STAGE = (`XLEN*2)/NUM_STAGE;

	logic [(`XLEN*2)-1:0] prod_in_reg;
	logic [(`XLEN*2)-1:0] partial_prod_reg;
	logic [(`XLEN*2)-1:0] partial_product;
	logic [(`XLEN*2)-1:0] next_mplier;
	logic [(`XLEN*2)-1:0] next_mcand;
	logic				  next_done;

	assign product_out 	   = (prod_in_reg + partial_prod_reg);
	assign partial_product = (mplier_in[STAGE-1:0] * mcand_in);
	assign next_mplier 	   = { {(STAGE){1'b0}}, mplier_in[(2*`XLEN)-1:(STAGE)] };
	assign next_mcand  	   = { mcand_in[(2*`XLEN)-(1+STAGE):0], {(STAGE){1'b0}} };
	assign next_done	   = (~reset & start);

	always_ff @(posedge clock) begin
		prod_in_reg      <= `SD product_in;
		partial_prod_reg <= `SD partial_product;
		mplier_out       <= `SD next_mplier;
		mcand_out        <= `SD next_mcand;
		done			 <= `SD next_done;
	end  // always_ff @(posedge clock)
endmodule  // mult_stage