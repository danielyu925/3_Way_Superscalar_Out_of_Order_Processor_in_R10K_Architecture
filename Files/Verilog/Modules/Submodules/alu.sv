//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :  alu.sv                                               //
//                                                                      //
//  Description :  alu submodule of the fu module;                      //
//                 given the command code CMD and proper operands A     //
//                 and B, compute the result of the instruction         // 
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module alu (
	input  			[`XLEN-1:0] opa,
	input  			[`XLEN-1:0] opb,
	input  ALU_FUNC     		func,
	output logic    [`XLEN-1:0] result
);
	wire signed [`XLEN-1:0] signed_opa;
	wire signed [`XLEN-1:0] signed_opb;

	assign signed_opa = opa;
	assign signed_opb = opb;

	always_comb begin
		case (func)
			ALU_ADD:   result = (opa + opb);
			ALU_SUB:   result = (opa - opb);
			ALU_AND:   result = (opa & opb);
			ALU_SLT:   result = (signed_opa < signed_opb);
			ALU_SLTU:  result = (opa < opb);
			ALU_OR:    result = (opa | opb);
			ALU_XOR:   result = (opa ^ opb);
			ALU_SRL:   result = (opa >> opb[4:0]);
			ALU_SLL:   result = (opa << opb[4:0]);
			ALU_SRA:   result = (signed_opa >>> opb[4:0]);  // arithmetic from logical shift
			default:   result = `XLEN'hfacebeec;  			// here to prevent latches
		endcase  // case (func)
	end  // always_comb  // result
endmodule  // alu