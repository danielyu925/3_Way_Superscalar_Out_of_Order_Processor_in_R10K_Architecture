/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__

/* Synthesis testing definition, used in DUT module instantiation */

`ifdef  SYNTH_TEST
`define DUT(mod) mod``_svsim
`else
`define DUT(mod) mod
`endif

//////////////////////////////////////////////
//TEST MODE ONLY
`define	TEST_MODE 

//////////////////////////////////////////////

`define SUPERSCALAR_WAYS	  3
`define N_PHYS_REG	  	  	  64
`define N_ARCH_REG	  	  	  32
`define N_RS_ENTRIES		  16
`define N_ROB_ENTRIES		  32
`define N_LSQ_ENTRIES 		  8

`define SUPERSCALAR_WAYS_BITS $clog2(`SUPERSCALAR_WAYS)
`define N_PHYS_REG_BITS   	  $clog2(`N_PHYS_REG)
`define N_ARCH_REG_BITS       $clog2(`N_ARCH_REG)
`define N_RS_ENTRIES_BITS	  $clog2(`N_RS_ENTRIES)
`define N_ROB_ENTRIES_BITS	  $clog2(`N_ROB_ENTRIES)
`define N_LSQ_ENTRIES_BITS	  $clog2(`N_LSQ_ENTRIES)

`define N_ALU_UNITS			  3
`define N_MULT_UNITS		  2
`define N_LS_UNITS			  2
`define N_BR_UNITS			  1
`define N_FU_UNITS			  `N_ALU_UNITS + `N_MULT_UNITS + `N_LS_UNITS + `N_BR_UNITS
`define N_FU_UNITS_BITS		  $clog2(`N_FU_UNITS)

//////////////////////////////////////////////
//
// Memory/testbench attribute definitions
//
//TODO CACHE_MODE MEM_LATENCY_IN_CYCLES
//////////////////////////////////////////////
// `define CACHE_MODE //removes the byte-level interface from the memory mode, DO NOT MODIFY!
`define NUM_MEM_TAGS           15

`define MEM_SIZE_IN_BYTES      (64*1024)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)

//you can change the clock period to whatever, 10 is just fine
`define VERILOG_CLOCK_PERIOD   12.0
`define SYNTH_CLOCK_PERIOD     12.0 // Clock period for synth and memory latency
`define MEM_LATENCY_IN_CYCLES  0
// `define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0] byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

//////////////////////////////////////////////
// Exception codes
// This mostly follows the RISC-V Privileged spec
// except a few add-ons for our infrastructure
// The majority of them won't be used, but it's
// good to know what they are
//////////////////////////////////////////////

typedef enum logic [3:0] {
	INST_ADDR_MISALIGN  = 4'h0,
	INST_ACCESS_FAULT   = 4'h1,
	ILLEGAL_INST        = 4'h2,
	BREAKPOINT          = 4'h3,
	LOAD_ADDR_MISALIGN  = 4'h4,
	LOAD_ACCESS_FAULT   = 4'h5,
	STORE_ADDR_MISALIGN = 4'h6,
	STORE_ACCESS_FAULT  = 4'h7,
	ECALL_U_MODE        = 4'h8,
	ECALL_S_MODE        = 4'h9,
	NO_ERROR            = 4'ha, //a reserved code that we modified for our purpose
	ECALL_M_MODE        = 4'hb,
	INST_PAGE_FAULT     = 4'hc,
	LOAD_PAGE_FAULT     = 4'hd,
	HALTED_ON_WFI       = 4'he, //another reserved code that we used
	STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;


//////////////////////////////////////////////
//
// Datapath control signals
//
//////////////////////////////////////////////

//
// ALU opA input mux selects
//
typedef enum logic [1:0] {
	OPA_IS_RS1  = 2'h0,
	OPA_IS_NPC  = 2'h1,
	OPA_IS_PC   = 2'h2,
	OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

//
// ALU opB input mux selects
//
typedef enum logic [3:0] {
	OPB_IS_RS2    = 4'h0,
	OPB_IS_I_IMM  = 4'h1,
	OPB_IS_S_IMM  = 4'h2,
	OPB_IS_B_IMM  = 4'h3,
	OPB_IS_U_IMM  = 4'h4,
	OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

// //
// // Destination register select
// //
// typedef enum logic [1:0] {
// 	DEST_RD = 2'h0,
// 	DEST_NONE  = 2'h1
// } DEST_REG_SEL;

//
// ALU function code input
// probably want to leave these alone
//
typedef enum logic [4:0] {
	ALU_ADD     = 5'h00,
	ALU_SUB     = 5'h01,
	ALU_SLT     = 5'h02,
	ALU_SLTU    = 5'h03,
	ALU_AND     = 5'h04,
	ALU_OR      = 5'h05,
	ALU_XOR     = 5'h06,
	ALU_SLL     = 5'h07,
	ALU_SRL     = 5'h08,
	ALU_SRA     = 5'h09,
	// ALU_MUL     = 5'h0a,
	// ALU_MULH    = 5'h0b,
	// ALU_MULHSU  = 5'h0c,
	// ALU_MULHU   = 5'h0d,
	ALU_DIV     = 5'h0e,
	ALU_DIVU    = 5'h0f,
	ALU_REM     = 5'h10,
	ALU_REMU    = 5'h11
} ALU_FUNC;

typedef enum logic [4:0] {
	ALU_MUL     = 5'h0a,
	ALU_MULH    = 5'h0b,
	ALU_MULHSU  = 5'h0c,
	ALU_MULHU   = 5'h0d
} MULT_FUNC;

typedef enum logic [4:0] {
	/* selects the camparision logic */ 
	BEQ		= 5'h0,
	BNE		= 5'h1,
	BLT		= 5'h4,
	BGE		= 5'h5,
	BLTU	= 5'h6,
	BGEU	= 5'h7,
	UNCOND	= 5'hf
} BR_FUNC;

//
// Basic NOP instruction.  Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
//
`define NOP 32'h13


//////////////////////////////////////////////
//
// Assorted things it is not wise to change
//
//////////////////////////////////////////////

//
// actually, you might have to change this if you change VERILOG_CLOCK_PERIOD
// JK you don't ^^^
//
`define SD #1


// the RISCV register file zero register, any read of this register always
// returns a zero value, and any write to this register is thrown away
//
`define ZERO_REG 5'd0

//
// Memory bus commands control signals
//
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;

`ifndef CACHE_MODE
typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
`endif
//
// useful boolean single-bit definitions
//
`define FALSE  1'h0
`define TRUE  1'h1

// RISCV ISA SPEC
`define XLEN 32
typedef union packed {
	logic [31:0] inst;
	struct packed {
		logic [6:0] funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} r; //register to register instructions
	struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1; //base
		logic [2:0]  funct3;
		logic [4:0]  rd;  //dest
		logic [6:0]  opcode;
	} i; //immediate or load instructions
	struct packed {
		logic [6:0] off; //offset[11:5] for calculating address
		logic [4:0] rs2; //source
		logic [4:0] rs1; //base
		logic [2:0] funct3;
		logic [4:0] set; //offset[4:0] for calculating address
		logic [6:0] opcode;
	} s; //store instructions
	struct packed {
		logic       of; //offset[12]
		logic [5:0] s;   //offset[10:5]
		logic [4:0] rs2;//source 2
		logic [4:0] rs1;//source 1
		logic [2:0] funct3;
		logic [3:0] et; //offset[4:1]
		logic       f;  //offset[11]
		logic [6:0] opcode;
	} b; //branch instructions
	struct packed {
		logic [19:0] imm;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} u; //upper immediate instructions
	struct packed {
		logic       of; //offset[20]
		logic [9:0] et; //offset[10:1]
		logic       s;  //offset[11]
		logic [7:0] f;	//offset[19:12]
		logic [4:0] rd; //dest
		logic [6:0] opcode;
	} j;  //jump instructions
`ifdef ATOMIC_EXT
	struct packed {
		logic [4:0] funct5;
		logic       aq;
		logic       rl;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} a; //atomic instructions
`endif
`ifdef SYSTEM_EXT
	struct packed {
		logic [11:0] csr;
		logic [4:0]  rs1;
		logic [2:0]  funct3;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} sys; //system call instructions
`endif

} INST; //instruction typedef, this should cover all types of instructions

typedef enum logic [$clog2(`N_FU_UNITS)-1:0] {
	LS_1 = 0,
	LS_2 = 1,
	ALU_1 = 2,
	ALU_2 = 3,
	ALU_3 = 4,
	MULT_1 = 5,
	MULT_2 = 6,
	BRANCH = 7
} FU_SELECT;

typedef enum logic [1:0]{
	alu = 0,
	mult = 1,
	br = 2
} OP_SELECT;


/////////////// STAGE PACKETS ////////////////

//////////////////////////////////////////////
//
// Fetch Packets:
// Data that is output by the Fetch Stage
//
//////////////////////////////////////////////

typedef struct packed {
	logic [`XLEN-1:0] NPC; 	  // PC + 4
	logic [`XLEN-1:0] PC;  	  // PC 
	logic 			  valid;  // instruction is valid
    INST 			  inst;
} FETCH_DISPATCH_PACKET;

///////////// END FETCH PACKETS //////////////


//////////////////////////////////////////////
//
// Dispatch Packets:
// Data that is output by the Dispatch Stage
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`SUPERSCALAR_WAYS_BITS-1:0] first_stall_idx;  // index of first inst stalled in dispatch
	logic enable;  										 // at least one instruction was stalled in dispatch
} DISPATCH_FETCH_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] t_idx;     // t reg
    logic [`N_PHYS_REG_BITS-1:0] told_idx;  // told reg
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;  	// architectural reg
    logic [`XLEN-1:0]            NPC;
    logic                        halt;    	// halt inst e.g., wfi
	logic                        enable;  	// true iff the instruction isn't already in the rob
    logic                        valid;   	// instruction is valid
} DISPATCH_ROB_PACKET;

typedef struct packed {
    logic [`SUPERSCALAR_WAYS-1:0] new_pr_en;  // instruction uses physical reg from freelist
} DISPATCH_FREELIST_PACKET;

typedef struct packed {
    logic [`XLEN-1:0] 				NPC;  			// PC + 4
    logic [`XLEN-1:0] 				PC;   			// PC

    logic [`N_PHYS_REG_BITS-1:0] 	reg1_pr_idx;
    logic [`N_PHYS_REG_BITS-1:0] 	reg2_pr_idx;
    logic [`N_PHYS_REG_BITS-1:0] 	pr_idx;
	logic [`N_ROB_ENTRIES_BITS-1:0] rob_idx;
    logic [`N_ARCH_REG_BITS-1:0]    ar_idx;

    ALU_OPA_SELECT 					opa_select; 	// ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT 					opb_select; 	// ALU opb mux select (ALU_OPB_xxx *)
    ALU_FUNC  						alu_func;   	// ALU function select (ALU_xxx *)
    MULT_FUNC 						mult_func;

    FU_SELECT      					fu_sel;
    OP_SELECT      					op_sel;

    logic 							reg1_ready;
    logic 							reg2_ready;
	logic 							rd_mem;     	// instruction reads from memory
	logic 							wr_mem;         // instruction writes to memory
	logic 							cond_branch;    // instruction is a conditional branch
	logic 							uncond_branch;  // instruction is an unconditional branch
	logic 							halt;           // instruction is a halt
	logic 							illegal;        // instruction is illegal
	logic 							csr_op;         // instruction is a CSR operation (we only used this as a cheap way to get return code)
	logic 							valid;          // instruction is valid
	logic 							enable;		 	// instruction should be added to the rs
	INST  							inst;
} DISPATCH_RS_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] pr_idx;  // the tag of physical register for rename
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;  // architecutre register of map table
	logic enable;  						  // map table should be updated
} DISPATCH_MAPTABLE_PACKET;

//////////// END DISPATCH PACKETS ////////////


//////////////////////////////////////////////
//
// Issue Packets:
// Data that is output by the Complete Stage
//
//////////////////////////////////////////////

typedef struct packed{
    logic [`XLEN-1:0] 				 NPC;  			 // PC + 4
	logic [`XLEN-1:0] 				 PC;   	 		 // PC

	logic [31:0] 					 rs1_value;  	 // reg A value
	logic [31:0] 					 rs2_value;  	 // reg B value

	ALU_OPA_SELECT 					 opa_select;  	 // ALU opa mux select (ALU_OPA_xxx *)
	ALU_OPB_SELECT 					 opb_select;  	 // ALU opb mux select (ALU_OPB_xxx *)

	logic [`N_PHYS_REG_BITS-1:0] 	 pr_idx;         // destination (writeback) physical register
	logic [`N_ARCH_REG_BITS-1:0] 	 ar_idx;   		 // destination (writeback) register index
	logic [`N_ROB_ENTRIES_BITS-1:0]  rob_idx;

    OP_SELECT 						 op_sel; 
	FU_SELECT 						 fu_select;
	ALU_FUNC  						 alu_func;   	 // ALU function select (ALU_xxx *)
    MULT_FUNC 						 mult_func; 

	logic 							 rd_mem;         // instruction reads from memory
	logic 							 wr_mem;         // instruction writes to memory
	logic 							 cond_branch;    // instruction is a conditional branch
	logic 							 uncond_branch;  // instruction is an unconditional branch
	logic							 halt;           // instruction is a halt
	logic 							 illegal;        // instruction is illegal
	logic 							 csr_op;         // instruction is a CSR operation (we only used this as a cheap way to get return code)
	logic 							 valid;          // instruction is valid
	INST  							 inst;
} ISSUE_FU_PACKET;

///////////// END ISSUE PACKETS //////////////


//////////////////////////////////////////////
//
// Complete Packets:
// Data that is output by the Complete Stage
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] t_idx;
} CDB_PACKET;

typedef struct packed {
    logic [`N_ROB_ENTRIES_BITS-1:0] rob_idx;  			    // instruction's index in the ROB
    logic                           complete;  			// instruction has been completed and is valid
	logic [`XLEN-1:0] 				dest_value; 		    // instruction result from fu
    logic                           precise_state_enable;  // instruction is a taken branch and requires precise state handling
    logic [`XLEN-1:0]               target_pc;
} COMPLETE_ROB_PACKET;  

typedef struct packed{
	logic [`N_ARCH_REG_BITS-1:0] ar_idx;
    logic [`XLEN-1:0] 			 dest_value;
    logic 						 rd_mem;
    logic 						 wr_mem;
    logic [`XLEN-1:0] 			 target_pc;
} COMPLETE_PRF_PACKET;

//////////// END COMPLETE PACKETS ////////////


//////////////////////////////////////////////
//
// Retire Packets:
// Data that is output by the Retire Stage
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] t_idx;
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;
    logic                        complete;
    logic [`XLEN-1:0]            NPC;
    logic [`XLEN-1:0]            dest_value;
} RETIRE_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] told_idx;  // physical register index that return to freelist
	logic 						 valid;  	// non-zero iff the index is ready
} RETIRE_FREELIST_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] t_idx;     			// t reg
    logic [`N_PHYS_REG_BITS-1:0] told_idx;  			// told reg
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;  				// architectural reg
    logic 						 complete;  			// instruction has been completed
    logic 						 precise_state_enable;  // precise state is needed when retire
    logic [`XLEN-1:0]			 target_pc;
} ROB_CONNECTION_ENTRY;

///////////// END RETIRE PACKETS /////////////

////////////// END STAGE PACKETS /////////////


/////////////// MODULE PACKETS ///////////////

//////////////////////////////////////////////
//
// ROB Packets:
// Data that is output by the ROB
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`SUPERSCALAR_WAYS-1:0]	 					   stall;  		   // stall signal from ROB
    logic [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] new_entry_idx;  // idx of new instr in ROB
} ROB_DISPATCH_PACKET;  

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] t_idx;     			// t reg
    logic [`N_PHYS_REG_BITS-1:0] told_idx;  			// told reg
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;  				// architectural reg
    logic                        complete;  			// instruction has been completed
    logic                        halt; 					// halt inst e.g., wfi
    logic [`XLEN-1:0]            NPC;
    logic                        precise_state_enable;  // precise state is needed when retire
    logic [`XLEN-1:0]            target_pc;
    logic [`XLEN-1:0]            dest_value;
} ROB_PACKET;

/////////////// END ROB PACKETS //////////////


//////////////////////////////////////////////
//
// FU Packets:
// Data that is output by the FU
//
//////////////////////////////////////////////

typedef struct packed{
	logic [`N_PHYS_REG_BITS-1:0] 	pr_idx;       // destination (writeback) physical register
	logic [`N_ARCH_REG_BITS-1:0] 	ar_idx;  	  // destination (writeback) register index
    logic [`N_ROB_ENTRIES_BITS-1:0] rob_idx;

    logic [`XLEN-1:0] 				target_pc;
    logic [`XLEN-1:0]      			dest_value;

	logic 							rd_mem;  	  // instruction reads from memory
	logic 							wr_mem;       // instruction writes to memory
	logic 							halt;         // instruction is a halt
    logic 							take_branch;  // instruction is a taken branch
    logic 							valid;        // instruction is valid
} FU_COMPLETE_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] idx;
    logic [`XLEN-1:0] 			 value;
} FU_PRF_PACKET;

typedef struct packed{
    logic alu_1;
    logic alu_2;
    logic alu_3;
    logic mult_1;
    logic mult_2;
    logic branch_1;
} FU_RS_PACKET;

/////////////// END FU PACKETS ///////////////


//////////////////////////////////////////////
//
// FREELIST Packets:
// Data that is output by the FREELIST
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] t_idx;  // free physical register index
	logic [`SUPERSCALAR_WAYS-1:0] 						valid;  // non_zero iff the index is ready
} FREELIST_DISPATCH_PACKET;

//////////// END FREELIST PACKETS ////////////


//////////////////////////////////////////////
//
// RS Packets:
// Data that is output by the RS
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`SUPERSCALAR_WAYS-1:0] stall;
} RS_DISPATCH_PACKET; 

typedef struct packed {
    logic [`XLEN-1:0] 				NPC;  			// PC + 4
    logic [`XLEN-1:0] 				PC;   			// PC

    logic [`N_PHYS_REG_BITS-1:0] 	reg1_pr_idx;
    logic [`N_PHYS_REG_BITS-1:0] 	reg2_pr_idx;
    logic [`N_PHYS_REG_BITS-1:0] 	pr_idx;
	logic [`N_ROB_ENTRIES_BITS-1:0] rob_idx;
    logic [`N_ARCH_REG_BITS-1:0]    ar_idx;

    ALU_OPA_SELECT 					opa_select; 	// ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT 					opb_select; 	// ALU opb mux select (ALU_OPB_xxx *)
    FU_SELECT      					fu_sel;
    OP_SELECT      					op_sel;

    ALU_FUNC  						alu_func;   	// ALU function select (ALU_xxx *)
    MULT_FUNC 						mult_func;

	logic 							rd_mem;         // instruction reads from memory
	logic 							wr_mem;         // instruction writes to memory
	logic 							cond_branch;    // instruction is a conditional branch
	logic 							uncond_branch;  // instruction is an unconditional branch
	logic 							halt;           // instruction is a halt
	logic 							illegal;        // instruction is illegal
	logic 							csr_op;         // instruction is a CSR operation (we only used this as a cheap way to get return code)
	logic 							valid;          // instruction is valid
	INST  							inst;
} RS_ISSUE_PACKET;

/////////////// END RS PACKETS ///////////////


//////////////////////////////////////////////
//
// MAP Packets:
// Data that is output by the MAP
//
//////////////////////////////////////////////

typedef struct packed {
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] map;   // map table
    logic [`N_ARCH_REG-1:0] 					  done;  // the + sign of map table
} MAPTABLE_PACKET;

////////////// END MAP PACKETS ///////////////


//////////////////////////////////////////////
//
// SQ Packets:
// Data that is output by the SQ
//
//////////////////////////////////////////////

typedef struct packed {
    logic             ready;
    logic [3:0]       usebytes;
    logic [`XLEN-1:0] addr; // must be aligned with words
    logic [`XLEN-1:0] data;
} SQ_ENTRY_PACKET;

typedef struct packed {
	logic			  stall;
	logic [3:0]		  usebytes;
	logic [`XLEN-1:0] data;
} SQ_LOAD_PACKET;

/////////////// END SQ PACKETS ///////////////


//////////////////////////////////////////////
//
// LQ Packets:
// Data that is output by the LQ
//
//////////////////////////////////////////////

typedef struct packed{
    logic [3:0]       validbtyes;
    logic             addr_ready;
    logic [3:0]		  tag;
    logic [`XLEN-1:0] addr; // must be aligned with words
    logic [`XLEN-1:0] data;
} LQ_ENTRY_PACKET;

typedef struct packed {
	logic [`N_LSQ_ENTRIES_BITS-1:0] tail_idx; // the tail position when load is dispatched
	logic [`XLEN-1:0]				addr; // must align with word! 
} LOAD_SQ_PACKET;

/////////////// END LQ PACKETS ///////////////

///////////// END MODULE PACKETS /////////////


////////////// MEMORY PACKETS ////////////////

///////////// END MEMORY PACKETS /////////////


//////////// CONNECTION PACKETS //////////////

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] told_idx;  // physical register index that return to freelist
	logic 						 valid;  	// non-zero iff the index is ready
} FREELIST_CONNECTION_PACKET;

typedef struct packed {
    logic [`N_PHYS_REG_BITS-1:0] t_idx;      
    logic [`N_ARCH_REG_BITS-1:0] ar_idx;
    logic 						 complete;
} RETIRE_CONNECTION_PACKET;

////////// END CONNECTION PACKETS ///////////

`endif // __SYS_DEFS_VH__