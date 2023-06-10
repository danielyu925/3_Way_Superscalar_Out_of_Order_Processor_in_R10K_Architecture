//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :    brcond.sv                                            //
//                                                                      //
//  Description :    brcond submodule of the fu module;                   //
//                 given the instruction code, compute the proper       //
//                 condition for the instruction; for branches this     //
//                 condition will indicate whether the target is taken  //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module brcond (
	input 		 [`XLEN-1:0] rs1,   // Value to check against condition
	input 		 [`XLEN-1:0] rs2,
	input 		 [2:0] 		 func,  // Specifies which condition to check

	output logic 			 cond   // 0/1 condition result (False/True)
);
	logic signed [`XLEN-1:0] signed_rs1;
	logic signed [`XLEN-1:0] signed_rs2;

	assign signed_rs1 = rs1;
	assign signed_rs2 = rs2;

	always_comb begin
		case (func)
            BEQ:      cond = (signed_rs1 == signed_rs2);
            BNE:      cond = (signed_rs1 != signed_rs2);
            BLT:      cond = (signed_rs1 <  signed_rs2);
            BGE:      cond = (signed_rs1 >= signed_rs2);
            BLTU:     cond = (rs1 <  rs2);
            BGEU:     cond = (rs1 >= rs2);
			UNCOND:   cond = `TRUE;
			default:  cond = `FALSE;
		endcase  // case (func)
	end  // always_comb  // cond
endmodule  // brcond