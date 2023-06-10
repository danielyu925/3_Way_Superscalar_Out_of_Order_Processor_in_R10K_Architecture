# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#

SOURCE = test_progs/simple_test/mult.s

CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

DEBUG_FLAG = -g
CFLAGS =  -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div 
OFLAGS = -O0
ASFLAGS = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS = -SD -M no-aliases 
OBJCFLAGS = --set-section-flags .bss=contents,alloc,readonly
OBJDFLAGS = -SD -M numeric,no-aliases

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################

ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJCOPY = riscv objcopy
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJCOPY = riscv64-unknown-elf-objcopy
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif


#
#VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -kdb -lca -debug_access+all
#For test coverage
VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -kdb -lca -debug_access+all -cm line+fsm+tgl+branch+assert

LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v


##--- SET MODULE NAMES --------------

export PIPELINE_NAME = pipeline
export ROB_NAME = rob
export FREELIST_NAME = freelist
export ARCH_NAME = arch
export PRF_NAME = prf
export MAPTABLE_NAME = maptable
export RS_NAME = rs
export FETCH_NAME = fetch
export DISPATCH_NAME = dispatch
export ISSUE_NAME = issue
export FU_NAME = fu
export COMPLETE_NAME = complete
export RETIRE_NAME = retire
export ICACHE_NAME = icache
export SQ_NAME = sq
export DISPATCH_RS_NAME = $(DISPATCH_NAME)_$(RS_NAME)
export DISPATCH_ROB_NAME = $(DISPATCH_NAME)_$(ROB_NAME)
export DISPATCH_FETCH_NAME = $(DISPATCH_NAME)_$(FETCH_NAME)
export DISPATCH_FREELIST_NAME = $(DISPATCH_NAME)_$(FREELIST_NAME)
export DISPATCH_MAPTABLE_NAME = $(DISPATCH_NAME)_$(MAPTABLE_NAME)
export DISPATCH_FETCH_RS_NAME = $(DISPATCH_FETCH_NAME)_$(RS_NAME)
export DISPATCH_FETCH_FREELIST_NAME = $(DISPATCH_FETCH_NAME)_$(FREELIST_NAME)
export DISPATCH_PIPE_NAME = $(DISPATCH_NAME)_pipe
export FU_COMPLETE_NAME = $(FU_NAME)_$(COMPLETE_NAME)
export RETIRE_ROB_ARCH_FREELIST_NAME = $(RETIRE_NAME)_$(ROB_NAME)_$(ARCH_NAME)_$(FREELIST_NAME)

# ADD_HERE - add new components' names above, example:
# export XXX_NAME = xxx


COMPONENT_NAMES = PIPELINE_NAME ARCH_NAME ROB_NAME FREELIST_NAME PRF_NAME MAPTABLE_NAME \
	RS_NAME ICACHE_NAME FETCH_NAME DISPATCH_NAME ISSUE_NAME COMPLETE_NAME FU_NAME RETIRE_NAME \
	DISPATCH_RS_NAME DISPATCH_ROB_NAME DISPATCH_FETCH_NAME DISPATCH_FREELIST_NAME \
	DISPATCH_MAPTABLE_NAME RETIRE_ROB_ARCH_FREELIST_NAME DISPATCH_FETCH_RS_NAME \
	DISPATCH_FETCH_FREELIST_NAME DISPATCH_PIPE_NAME FU_COMPLETE_NAME SQ_NAME

# ADD_HERE - add new components' names to the list above, example:
# COMPONENT_NAMES = PIPELINE_NAME ... \ 
#	  DISPATCH_FETCH_FREELIST_NAME ... FU_COMPLETE_NAME XXX_NAME


##--- Directories Setting --------------

SYNTH_DIR = ./synth

VERILOG_DIR = verilog
TEST_DIR = testbench

MODULES_DIR = $(VERILOG_DIR)/modules
SUBMODULES_DIR = $(MODULES_DIR)/submodules
STAGES_DIR = $(VERILOG_DIR)/stages
MEMORY_DIR = $(VERILOG_DIR)/memory
CONNECTIONS_DIR = $(VERILOG_DIR)/connections

TEST_MODULES_DIR = $(TEST_DIR)/modules
TEST_STAGES_DIR = $(TEST_DIR)/stages
TEST_MEMORY_DIR = $(TEST_DIR)/memory
TEST_CONNECTIONS_DIR = $(TEST_DIR)/connections


##--- Modules Files Setting --------------

# ROB
ROBSYNFILES = $(SYNTH_DIR)/$(ROB_NAME).vg
ROBTESTBENCH = $(TEST_MODULES_DIR)/$(ROB_NAME)_testbench.sv
export ROBFILES = $(MODULES_DIR)/$(ROB_NAME).sv

# FREELIST
FREELISTSYNFILES = $(SYNTH_DIR)/$(FREELIST_NAME).vg
FREELISTTESTBENCH = $(TEST_MODULES_DIR)/$(FREELIST_NAME)_testbench.sv
export FREELISTFILES = $(MODULES_DIR)/$(FREELIST_NAME).sv $(SUBMODULES_DIR)/ps.sv

# ARCH
ARCHSYNFILES = $(SYNTH_DIR)/$(ARCH_NAME).vg
ARCHTESTBENCH = $(TEST_MODULES_DIR)/$(ARCH_NAME)_testbench.sv
export ARCHFILES = $(MODULES_DIR)/$(ARCH_NAME).sv

# RS
RSSYNFILES = $(SYNTH_DIR)/$(RS_NAME).vg
RSTESTBENCH = $(TEST_MODULES_DIR)/$(RS_NAME)_testbench.sv
export RSFILES = $(MODULES_DIR)/$(RS_NAME).sv $(SUBMODULES_DIR)/ps.sv

# PRF
PRFSYNFILES = $(SYNTH_DIR)/$(PRF_NAME).vg
PRFTESTBENCH = $(TEST_MEMORY_DIR)/$(PRF_NAME)_testbench.sv
export PRFFILES = $(MEMORY_DIR)/$(PRF_NAME).sv

# MAPTABLE
MAPTABLESYNFILES = $(SYNTH_DIR)/$(MAPTABLE_NAME).vg
MAPTABLETESTBENCH = $(TEST_MODULES_DIR)/$(MAPTABLE_NAME)_testbench.sv
export MAPTABLEFILES = $(MODULES_DIR)/$(MAPTABLE_NAME).sv

# FETCH
FETCHSYNFILES = $(SYNTH_DIR)/$(FETCH_NAME).vg
FETCHTESTBENCH = $(TEST_STAGES_DIR)/$(FETCH_NAME)_testbench.sv
export FETCHFILES = $(STAGES_DIR)/$(FETCH_NAME).sv

# DISPATCH
DISPATCHSYNFILES = $(SYNTH_DIR)/$(DISPATCH_NAME).vg
DISPATCHTESTBENCH = $(TEST_STAGES_DIR)/$(DISPATCH_NAME)_testbench.sv 
export DISPATCHFILES = $(STAGES_DIR)/$(DISPATCH_NAME).sv $(SUBMODULES_DIR)/decoder.sv

# ISSUE
ISSUESYNFILES = $(SYNTH_DIR)/$(ISSUE_NAME).vg
ISSUETESTBENCH = $(TEST_STAGES_DIR)/$(ISSUE_NAME)_testbench.sv
export ISSUEFILES = $(STAGES_DIR)/$(ISSUE_NAME).sv

# FU
FUSYNFILES = $(SYNTH_DIR)/$(FU_NAME).vg
FUTESTBENCH = $(TEST_MODULES_DIR)/$(FU_NAME)_testbench.sv
export FUFILES = $(MODULES_DIR)/$(FU_NAME).sv $(SUBMODULES_DIR)/alu.sv $(SUBMODULES_DIR)/brcond.sv \
	$(SUBMODULES_DIR)/fu_alu.sv $(SUBMODULES_DIR)/mult_stage.sv $(SUBMODULES_DIR)/mult.sv

# COMPLETE
COMPLETESYNFILES = $(SYNTH_DIR)/$(COMPLETE_NAME).vg
COMPLETETESTBENCH = $(TEST_STAGES_DIR)/$(COMPLETE_NAME)_testbench.sv
export COMPLETEFILES = $(STAGES_DIR)/$(COMPLETE_NAME).sv

# RETIRE
RETIRESYNFILES = $(SYNTH_DIR)/$(RETIRE_NAME).vg
RETIRETESTBENCH = $(TEST_STAGES_DIR)/$(RETIRE_NAME)_testbench.sv
export RETIREFILES = $(STAGES_DIR)/$(RETIRE_NAME).sv

# ICACHE
ICACHESYNFILES = $(SYNTH_DIR)/$(ICACHE_NAME).vg
ICACHETESTBENCH = $(TEST_MEMORY_DIR)/$(ICACHE_NAME)_testbench.sv
export ICACHEFILES = $(MEMORY_DIR)/$(ICACHE_NAME).sv

# SQ
SQSYNFILES = $(SYNTH_DIR)/$(SQ_NAME).vg
SQTESTBENCH = $(TEST_MODULES_DIR)/$(SQ_NAME)_testbench.sv
export SQFILES = $(MODULES_DIR)/$(SQ_NAME).sv $(SUBMODULES_DIR)/ps.sv

# DISPATCH-RS CONNECTION
DISPATCHRSSYNFILES = $(SYNTH_DIR)/$(DISPATCH_RS_NAME).vg
DISPATCHRSTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_RS_NAME)_testbench.sv
export DISPATCHRSFILES = $(DISPATCHFILES) $(RSFILES) $(CONNECTIONS_DIR)/$(DISPATCH_RS_NAME).sv

# DISPATCH-ROB CONNECTION
DISPATCHROBSYNFILES = $(SYNTH_DIR)/$(DISPATCH_ROB_NAME).vg
DISPATCHROBTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_ROB_NAME)_testbench.sv
export DISPATCHROBFILES = $(DISPATCHFILES) $(ROBFILES) $(CONNECTIONS_DIR)/$(DISPATCH_ROB_NAME).sv

# DISPATCH-FETCH CONNECTION
DISPATCHFETCHSYNFILES = $(SYNTH_DIR)/$(DISPATCH_FETCH_NAME).vg
DISPATCHFETCHTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_FETCH_NAME)_testbench.sv
export DISPATCHFETCHFILES = $(DISPATCHFILES) $(FETCHFILES) $(CONNECTIONS_DIR)/$(DISPATCH_FETCH_NAME).sv

# DISPATCH-FREELIST CONNECTION
DISPATCHFREELISTSYNFILES = $(SYNTH_DIR)/$(DISPATCH_FREELIST_NAME).vg
DISPATCHFREELISTTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_FREELIST_NAME)_testbench.sv
export DISPATCHFREELISTFILES = $(DISPATCHFILES) $(FREELISTFILES) $(CONNECTIONS_DIR)/$(DISPATCH_FREELIST_NAME).sv

# DISPATCH-MAPTABLE CONNECTION
DISPATCHMAPTABLESYNFILES = $(SYNTH_DIR)/$(DISPATCH_MAPTABLE_NAME).vg
DISPATCHMAPTABLETESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_MAPTABLE_NAME)_testbench.sv
export DISPATCHMAPTABLEFILES = $(DISPATCHFILES) $(MAPTABLEFILES) $(CONNECTIONS_DIR)/$(DISPATCH_MAPTABLE_NAME).sv

# DISPATCH-FETCH-RS CONNECTION
DISPATCHFETCHRSSYNFILES = $(SYNTH_DIR)/$(DISPATCH_FETCH_RS_NAME).vg
DISPATCHFETCHRSTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_FETCH_RS_NAME)_testbench.sv
export DISPATCHFETCHRSFILES = $(DISPATCHFILES) $(FETCHFILES) $(RSFILES) \
	$(CONNECTIONS_DIR)/$(DISPATCH_FETCH_RS_NAME).sv

# DISPATCH-FETCH-FREELIST CONNECTION
DISPATCHFETCHFREELISTSYNFILES = $(SYNTH_DIR)/$(DISPATCH_FETCH_FREELIST_NAME).vg
DISPATCHFETCHFREELISTTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_FETCH_FREELIST_NAME)_testbench.sv
export DISPATCHFETCHFREELISTFILES = $(DISPATCHFILES) $(FETCHFILES) $(FREELISTFILES) \
	$(CONNECTIONS_DIR)/$(DISPATCH_FETCH_FREELIST_NAME).sv

# RETIRE-ROB-ARCH-FREELIST CONNECTION
RETIREROBARCHFREELISTSYNFILES = $(SYNTH_DIR)/$(RETIRE_ROB_ARCH_FREELIST_NAME).vg
RETIREROBARCHFREELISTTESTBENCH = $(TEST_CONNECTIONS_DIR)/$(RETIRE_ROB_ARCH_FREELIST_NAME)_testbench.sv
export RETIREROBARCHFREELISTFILES = $(RETIREFILES) $(ROBFILES) $(ARCHFILES) $(FREELISTFILES) \
	$(CONNECTIONS_DIR)/$(RETIRE_ROB_ARCH_FREELIST_NAME).sv

# DISPATCH CONNECTIONS
DISPATCHPIPESYNFILES = $(SYNTH_DIR)/$(DISPATCH_PIPE_NAME).vg
DISPATCHPIPETESTBENCH = $(TEST_CONNECTIONS_DIR)/$(DISPATCH_PIPE_NAME)_testbench.sv
export DISPATCHPIPEFILES = $(DISPATCHFILES) $(RSFILES) $(ROBFILES) $(FETCHFILES) \
	$(FREELISTFILES) $(MAPTABLEFILES) $(CONNECTIONS_DIR)/$(DISPATCH_PIPE_NAME).sv

# FU-COMPLETE CONNECTION
FUCOMPLETESYNFILES = $(SYNTH_DIR)/$(FU_COMPLETE_NAME).vg
FUCOMPLETETESTBENCH = $(TEST_CONNECTIONS_DIR)/$(FU_COMPLETE_NAME)_testbench.sv
export FUCOMPLETEFILES = $(FUFILES) $(COMPLETEFILES) $(CONNECTIONS_DIR)/$(FU_COMPLETE_NAME).sv

# PIPELINE CONNECTIONS
PIPELINESYNFILES = $(SYNTH_DIR)/$(PIPELINE_NAME).vg
PIPELINETESTBENCH = $(TEST_DIR)/$(PIPELINE_NAME)_testbench.sv
export PIPELINEFILES = $(DISPATCHFILES) $(RSFILES) $(ROBFILES) $(FETCHFILES) \
	$(ARCHFILES) $(PRFFILES) $(ISSUEFILES) $(FUFILES) $(COMPLETEFILES) $(RETIREFILES) \
	$(FREELISTFILES) $(MAPTABLEFILES) $(VERILOG_DIR)/$(PIPELINE_NAME).sv

# ADD_HERE - add new components' info above, example:
# XXXSYNFILES = $(SYNTH_DIR)/$(XXX_NAME).vg
# XXXTESTBENCH = <TEST_PATH>/$(XXX_NAME)_testbench.sv
# XXXFILES = <PATH>/$(XXX_NAME).sv
# Replace <TEST_PATH> with:
#	$(TEST_MODULES_DIR) if the component is in $(VERILOG_DIR)/modules	OR
#	$(TEST_STAGES_DIR) if the component is in $(VERILOG_DIR)/stages	OR
#	$(TEST_MEMORY_DIR) if the component is in $(VERILOG_DIR)/memory
# Replace <PATH> with:
#	$(MODULES_DIR) if the component is in $(VERILOG_DIR)/modules	OR
#	$(STAGES_DIR) if the component is in $(VERILOG_DIR)/stages		OR
#	$(MEMORY_DIR) if the component is in $(VERILOG_DIR)/memory

 
 
# SIMULATION CONFIG

HEADERS     = $(wildcard *.svh)

TESTBENCH =  testbench/testbench.sv testbench/mem.sv testbench/pipe_print.c # Include only pipeline microarch files

PIPEFILES   = $(wildcard verilog/*.sv)

SIMFILES    = $(PIPEFILES)

#------SYNTHESIS CONFIG----------------------------

export HEADERS

#PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
#SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv

# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clock
export RESET_NET_NAME = reset
export CLOCK_PERIOD   = 12	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
                                #       and make this more aggressive


################################################################################
## RULES
################################################################################

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

#----Simulation------------------------------:

sim:	simv
	./simv | tee sim_program.out

simv:	$(HEADERS) $(PIPELINEFILES) $(PIPELINETESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim

# ROB simulation
$(ROB_NAME)_simv:	$(HEADERS) $(ROBFILES) $(ROBTESTBENCH)
	$(VCS) $^ -o $(ROB_NAME)_simv

# FREELIST simulation
$(FREELIST_NAME)_simv:	$(HEADERS) $(FREELISTFILES) $(FREELISTTESTBENCH)
	$(VCS) $^ -o $(FREELIST_NAME)_simv

# ARCH simulation
$(ARCH_NAME)_simv:	$(HEADERS) $(ARCHFILES) $(ARCHTESTBENCH)
	$(VCS) $^ -o $(ARCH_NAME)_simv

# RS simulation
$(RS_NAME)_simv:	$(HEADERS) $(RSFILES) $(RSTESTBENCH)
	$(VCS) $^ -o $(RS_NAME)_simv

# PRF simulation
$(PRF_NAME)_simv:	$(HEADERS) $(PRFFILES) $(PRFTESTBENCH)
	$(VCS) $^ -o $(PRF_NAME)_simv

# MAPTABLE simulation
$(MAPTABLE_NAME)_simv:	$(HEADERS) $(MAPTABLEFILES) $(MAPTABLETESTBENCH)
	$(VCS) $^ -o $(MAPTABLE_NAME)_simv

# FETCH simulation
$(FETCH_NAME)_simv:	$(HEADERS) $(FETCHFILES) $(FETCHTESTBENCH)
	$(VCS) $^ -o $(FETCH_NAME)_simv

# DISPATCH simulation
$(DISPATCH_NAME)_simv:	$(HEADERS) $(DISPATCHFILES) $(DISPATCHTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_NAME)_simv

# ISSUE simulation
$(ISSUE_NAME)_simv:	$(HEADERS) $(ISSUEFILES) $(ISSUETESTBENCH)
	$(VCS) $^ -o $(ISSUE_NAME)_simv

# FU simulation
$(FU_NAME)_simv:	$(HEADERS) $(FUFILES) $(FUTESTBENCH)
	$(VCS) $^ -o $(FU_NAME)_simv

# COMPLETE simulation
$(COMPLETE_NAME)_simv:	$(HEADERS) $(COMPLETEFILES) $(COMPLETETESTBENCH)
	$(VCS) $^ -o $(COMPLETE_NAME)_simv

# RETIRE simulation
$(RETIRE_NAME)_simv:	$(HEADERS) $(RETIREFILES) $(RETIRETESTBENCH)
	$(VCS) $^ -o $(RETIRE_NAME)_simv

# ICACHE simulation
$(ICACHE_NAME)_simv:	$(HEADERS) $(ICACHEFILES) $(ICACHETESTBENCH)
	$(VCS) $^ -o $(ICACHE_NAME)_simv

# SQ simulation
$(SQ_NAME)_simv:	$(HEADERS) $(SQFILES) $(SQTESTBENCH)
	$(VCS) $^ -o $(SQ_NAME)_simv

$(DISPATCH_RS_NAME)_simv:	$(HEADERS) $(DISPATCHRSFILES) $(DISPATCHRSTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_RS_NAME)_simv

$(DISPATCH_ROB_NAME)_simv:	$(HEADERS) $(DISPATCHROBFILES) $(DISPATCHROBTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_ROB_NAME)_simv

$(DISPATCH_FETCH_NAME)_simv:	$(HEADERS) $(DISPATCHFETCHFILES) $(DISPATCHFETCHTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_FETCH_NAME)_simv

$(DISPATCH_FREELIST_NAME)_simv:	$(HEADERS) $(DISPATCHFREELISTFILES) $(DISPATCHFREELISTTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_FREELIST_NAME)_simv

$(DISPATCH_MAPTABLE_NAME)_simv:	$(HEADERS) $(DISPATCHMAPTABLEFILES) $(DISPATCHMAPTABLETESTBENCH)
	$(VCS) $^ -o $(DISPATCH_MAPTABLE_NAME)_simv

$(DISPATCH_FETCH_RS_NAME)_simv:	$(HEADERS) $(DISPATCHFETCHRSFILES) $(DISPATCHFETCHRSTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_FETCH_RS_NAME)_simv

$(DISPATCH_FETCH_FREELIST_NAME)_simv:	$(HEADERS) $(DISPATCHFETCHFREELISTFILES) $(DISPATCHFETCHFREELISTTESTBENCH)
	$(VCS) $^ -o $(DISPATCH_FETCH_FREELIST_NAME)_simv

$(RETIRE_ROB_ARCH_FREELIST_NAME)_simv:	$(HEADERS) $(RETIREROBARCHFREELISTFILES) $(RETIREROBARCHFREELISTTESTBENCH)
	$(VCS) $^ -o $(RETIRE_ROB_ARCH_FREELIST_NAME)_simv

$(DISPATCH_PIPE_NAME)_simv:	$(HEADERS) $(DISPATCHPIPEFILES) $(DISPATCHPIPETESTBENCH)
	$(VCS) $^ -o $(DISPATCH_PIPE_NAME)_simv

$(FU_COMPLETE_NAME)_simv:	$(HEADERS) $(FUCOMPLETEFILES) $(FUCOMPLETETESTBENCH)
	$(VCS) $^ -o $(FU_COMPLETE_NAME)_simv

$(PIPELINE_NAME)_simv:	$(HEADERS) $(PIPELINEFILES) $(PIPELINETESTBENCH)
	$(VCS) $^ -o $(PIPELINE_NAME)_simv

# ADD_HERE - add make xxx_simv for new components above, example:
# $(XXX_NAME)_simv:	$(HEADERS) $(XXXFILES) $(XXXTESTBENCH)
#	 $(VCS) $^ -o $(XXX_NAME)_simv

# Function to auto define make xxx and make xxx_verdi_cov commands
define PARTIAL_SIMULATION
$($1):	$($1)_simv
	./$($1)_simv | tee $($1)_simv_program.out

$($1)_verdi_cov:	$($1)_simv
	./$($1)_simv -cm line+fsm+tgl+branch+assert
	./$($1)_simv -gui=verdi -cov -covdir $($1)_simv.vdb
endef

# Defines xxx and xxx verdi_cov commands for all modules and stages
$(foreach N,$(COMPONENT_NAMES),$(eval $(call PARTIAL_SIMULATION,$N)))


#---- Assemble Program --------------------------------

compile: $(CRT) $(LINKERS)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf

assemble: $(ASLINKERS)
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf 
	cp program.elf program.debug.elf

disassemble: program.debug.elf
	$(OBJCOPY) $(OBJCFLAGS) program.debug.elf
	$(OBJDUMP) $(OBJFLAGS) program.debug.elf > program.dump
	$(OBJDUMP) $(OBJDFLAGS) program.debug.elf > program.debug.dump
	rm program.debug.elf

hex: program.elf
	$(ELF2HEX) 8 8192 program.elf > program.mem

program: compile disassemble hex
	@:

debug_program:
	gcc -lm -g -std=gnu11 -DDEBUG $(SOURCE) -o debug_bin

assembly: assemble disassemble hex
	@:


#----Synthesis-----------------------------------

## Generate *.vg

#$(PIPELINE):	$(SIMFILES) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
#	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out
#	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(PIPELINE)

# ROB
$(ROBSYNFILES):	$(ROBFILES) $(SYNTH_DIR)/$(ROB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ROB_NAME).tcl | tee $(ROB_NAME)_synth.out

# FREELIST
$(FREELISTSYNFILES):	$(FREELISTFILES) $(SYNTH_DIR)/$(FREELIST_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FREELIST_NAME).tcl | tee $(FREELIST_NAME)_synth.out

# ARCH 
$(ARCHSYNFILES): $(ARCHFILES) $(SYNTH_DIR)/$(ARCH_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ARCH_NAME).tcl | tee $(ARCH_NAME)_synth.out

# RS 
$(RSSYNFILES):	$(RSFILES) $(SYNTH_DIR)/$(RS_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(RS_NAME).tcl | tee $(RS_NAME)_synth.out

# PRF 
$(PRFSYNFILES):	$(PRFFILES) $(SYNTH_DIR)/$(PRF_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PRF_NAME).tcl | tee $(PRF_NAME)_synth.out

# MAPTABLE 
$(MAPTABLESYNFILES):	$(MAPTABLEFILES) $(SYNTH_DIR)/$(MAPTABLE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(MAPTABLE_NAME).tcl | tee $(MAPTABLE_NAME)_synth.out

# FETCH 
$(FETCHSYNFILES):	$(FETCHFILES) $(SYNTH_DIR)/$(FETCH_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FETCH_NAME).tcl | tee $(FETCH_NAME)_synth.out

# DISPATCH
$(DISPATCHSYNFILES):	$(DISPATCHFILES) $(SYNTH_DIR)/$(DISPATCH_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_NAME).tcl | tee $(DISPATCH_NAME)_synth.out

# ISSUE 
$(ISSUESYNFILES):	$(ISSUEFILES) $(SYNTH_DIR)/$(ISSUE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ISSUE_NAME).tcl | tee $(ISSUE_NAME)_synth.out

# FU
$(FUSYNFILES):	$(FUFILES) $(SYNTH_DIR)/$(FU_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FU_NAME).tcl | tee $(FU_NAME)_synth.out

# COMPLETE 
$(COMPLETESYNFILES):	$(COMPLETEFILES) $(SYNTH_DIR)/$(COMPLETE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(COMPLETE_NAME).tcl | tee $(COMPLETE_NAME)_synth.out

# RETIRE
$(RETIRESYNFILES):	$(RETIREFILES) $(SYNTH_DIR)/$(RETIRE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(RETIRE_NAME).tcl | tee $(RETIRE_NAME)_synth.out

# ICACHE
$(ICACHESYNFILES):	$(ICACHEFILES) $(SYNTH_DIR)/$(ICACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ICACHE_NAME).tcl | tee $(ICACHE_NAME)_synth.out

# SQ
$(SQSYNFILES):	$(SQFILES) $(SYNTH_DIR)/$(SQ_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(SQ_NAME).tcl | tee $(ICACHE_NAME)_synth.out

# DISPATCH-RS CONNECTION
$(DISPATCHRSSYNFILES):	$(DISPATCHRSFILES) $(SYNTH_DIR)/$(DISPATCH_RS_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_RS_NAME).tcl | tee $(DISPATCH_RS_NAME)_synth.out

# DISPATCH-ROB CONNECTION
$(DISPATCHROBSYNFILES):	$(DISPATCHROBFILES) $(SYNTH_DIR)/$(DISPATCH_ROB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_ROB_NAME).tcl | tee $(DISPATCH_ROB_NAME)_synth.out

# DISPATCH-FETCH CONNECTION
$(DISPATCHFETCHSYNFILES):	$(DISPATCHFETCHFILES) $(SYNTH_DIR)/$(DISPATCH_FETCH_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_FETCH_NAME).tcl | tee $(DISPATCH_FETCH_NAME)_synth.out

# DISPATCH-FREELIST CONNECTION
$(DISPATCHFREELISTSYNFILES):	$(DISPATCHFREELISTFILES) $(SYNTH_DIR)/$(DISPATCH_FREELIST_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_FREELIST_NAME).tcl | tee $(DISPATCH_FREELIST_NAME)_synth.out

# DISPATCH-MAPTABLE CONNECTION
$(DISPATCHMAPTABLESYNFILES):	$(DISPATCHMAPTABLEFILES) $(SYNTH_DIR)/$(DISPATCH_MAPTABLE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_MAPTABLE_NAME).tcl | tee $(DISPATCH_MAPTABLE_NAME)_synth.out

# DISPATCH-FETCH CONNECTION
$(DISPATCHFETCHRSSYNFILES):	$(DISPATCHFETCHRSFILES) $(SYNTH_DIR)/$(DISPATCH_FETCH_RS_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_FETCH_RS_NAME).tcl | tee $(DISPATCH_FETCH_RS_NAME)_synth.out

# DISPATCH-FETCH-FREELIST CONNECTION
$(DISPATCHFETCHFREELISTSYNFILES):	$(DISPATCHFETCHFREELISTFILES) $(SYNTH_DIR)/$(DISPATCH_FETCH_FREELIST_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_FETCH_FREELIST_NAME).tcl | tee $(DISPATCH_FETCH_FREELIST_NAME)_synth.out

# RETIRE_ROB_ARCH_FREELIST CONNECTION
$(RETIREROBARCHFREELISTSYNFILES):	$(RETIREROBARCHFREELISTFILES) $(SYNTH_DIR)/$(RETIRE_ROB_ARCH_FREELIST_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(RETIRE_ROB_ARCH_FREELIST_NAME).tcl | tee $(RETIRE_ROB_ARCH_FREELIST_NAME)_synth.out 

# DISPATCH CONNECTIONS
$(DISPATCHPIPESYNFILES):	$(DISPATCHPIPEFILES) $(SYNTH_DIR)/$(DISPATCH_PIPE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DISPATCH_PIPE_NAME).tcl | tee $(DISPATCH_PIPE_NAME)_synth.out

# DISPATCH CONNECTIONS
$(FUCOMPLETESYNFILES):	$(FUCOMPLETEFILES) $(SYNTH_DIR)/$(FU_COMPLETE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FU_COMPLETE_NAME).tcl | tee $(FU_COMPLETE_NAME)_synth.out

# PIPELINE CONNECTIONS
$(PIPELINESYNFILES):	$(PIPELINEFILES) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out

# ADD_HERE - add make xxx.vg command for new components above, example:
# $(XXXSYNFILES):	$(XXXFILES) $(SYNTH_DIR)/$(XXX_NAME).tcl
#	 cd $(SYNTH_DIR) && dc_shell-t -f ./$(XXX_NAME).tcl | tee $(XXX_NAME)_synth.out

## All
syn:	syn_simv 
	./syn_simv | tee syn_program.out

syn_simv:	$(HEADERS) $(PIPELINESYNFILES) $(PIPELINETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

## ROB Synthesis
$(ROB_NAME)_syn_simv:	$(HEADERS) $(ROBSYNFILES) $(ROBTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(ROB_NAME)_syn_simv

# FREELIST Synthesis
$(FREELIST_NAME)_syn_simv:	$(HEADERS) $(FREELISTSYNFILES) $(FREELISTTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(FREELIST_NAME)_syn_simv

# ARCH Synthesis
$(ARCH_NAME)_syn_simv:	$(HEADERS) $(ARCHSYNFILES) $(ARCHTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(ARCH_NAME)_syn_simv

# RS Synthesis
$(RS_NAME)_syn_simv:	$(HEADERS) $(RSSYNFILES) $(RSTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(RS_NAME)_syn_simv

# PRF Synthesis
$(PRF_NAME)_syn_simv:	$(HEADERS) $(PRFSYNFILES) $(PRFTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(PRF_NAME)_syn_simv

# MAPTABLE Synthesis
$(MAPTABLE_NAME)_syn_simv:	$(HEADERS) $(MAPTABLESYNFILES) $(MAPTABLETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(MAPTABLE_NAME)_syn_simv

# FETCH Synthesis
$(FETCH_NAME)_syn_simv:	$(HEADERS) $(FETCHSYNFILES) $(FETCHTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(FETCH_NAME)_syn_simv

# DISPATCH Synthesis
$(DISPATCH_NAME)_syn_simv:	$(HEADERS) $(DISPATCHSYNFILES) $(DISPATCHTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_NAME)_syn_simv

# ISSUE Synthesis
$(ISSUE_NAME)_syn_simv:	$(HEADERS) $(ISSUESYNFILES) $(ISSUETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(ISSUE_NAME)_syn_simv

# FU Synthesis
$(FU_NAME)_syn_simv:	$(HEADERS) $(FUSYNFILES) $(FUTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(FU_NAME)_syn_simv

# COMPLETE Synthesis
$(COMPLETE_NAME)_syn_simv:	$(HEADERS) $(COMPLETESYNFILES) $(COMPLETETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(COMPLETE_NAME)_syn_simv

# RETIRE Synthesis
$(RETIRE_NAME)_syn_simv:	$(HEADERS) $(RETIRESYNFILES) $(RETIRETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(RETIRE_NAME)_syn_simv

# ICACHE Synthesis
$(ICACHE_NAME)_syn_simv:	$(HEADERS) $(ICACHESYNFILES) $(ICACHETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(ICACHE_NAME)_syn_simv

# SQ Synthesis
$(SQ_NAME)_syn_simv:	$(HEADERS) $(SQSYNFILES) $(SQTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(SQ_NAME)_syn_simv

# DISPATCH-RS CONNECTION Synthesis
$(DISPATCH_RS_NAME)_syn_simv:	$(HEADERS) $(DISPATCHRSSYNFILES) $(DISPATCHRSTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_RS_NAME)_syn_simv

# DISPATCH-ROB CONNECTION Synthesis
$(DISPATCH_ROB_NAME)_syn_simv:	$(HEADERS) $(DISPATCHROBSYNFILES) $(DISPATCHROBTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_ROB_NAME)_syn_simv

# DISPATCH-FETCH CONNECTION Synthesis
$(DISPATCH_FETCH_NAME)_syn_simv:	$(HEADERS) $(DISPATCHFETCHSYNFILES) $(DISPATCHFETCHTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_FETCH_NAME)_syn_simv

# DISPATCH-FREELIST CONNECTION Synthesis
$(DISPATCH_FREELIST_NAME)_syn_simv:	$(HEADERS) $(DISPATCHFREELISTSYNFILES) $(DISPATCHFREELISTTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_FREELIST_NAME)_syn_simv

# DISPATCH-MAPTABLE CONNECTION Synthesis
$(DISPATCH_MAPTABLE_NAME)_syn_simv:	$(HEADERS) $(DISPATCHMAPTABLESYNFILES) $(DISPATCHMAPTABLETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_MAPTABLE_NAME)_syn_simv

# DISPATCH-FETCH-RS CONNECTION Synthesis
$(DISPATCH_FETCH_RS_NAME)_syn_simv:	$(HEADERS) $(DISPATCHFETCHRSSYNFILES) $(DISPATCHFETCHRSTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_FETCH_RS_NAME)_syn_simv

# DISPATCH-FETCH-FREELIST CONNECTION Synthesis
$(DISPATCH_FETCH_FREELIST_NAME)_syn_simv:	$(HEADERS) $(DISPATCHFETCHFREELISTSYNFILES) $(DISPATCHFETCHFREELISTTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_FETCH_FREELIST_NAME)_syn_simv

# RETIRE_ROB_ARCH_FREELIST Synthesis
$(RETIRE_ROB_ARCH_FREELIST_NAME)_syn_simv:	$(HEADERS) $(RETIREROBARCHFREELISTFILES) $(RETIREROBARCHFREELISTTESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(RETIRE_ROB_ARCH_FREELIST_NAME)_syn_simv

# DISPATCH CONNECTIONS Synthesis
$(DISPATCH_PIPE_NAME)_syn_simv:	$(HEADERS) $(DISPATCHPIPESYNFILES) $(DISPATCHPIPETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(DISPATCH_PIPE_NAME)_syn_simv

# DISPATCH CONNECTIONS Synthesis
$(FU_COMPLETE_NAME)_syn_simv:	$(HEADERS) $(FUCOMPLETESYNFILES) $(FUCOMPLETETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(FU_COMPLETE_NAME)_syn_simv

# PIPELINE CONNECTIONS Synthesis
$(PIPELINE_NAME)_syn_simv:	$(HEADERS) $(PIPELINESYNFILES) $(PIPELINETESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(PIPELINE_NAME)_syn_simv

# ADD_HERE - add make xxx_simv for new components above, example:
# $(XXX_NAME)_syn_simv:	$(HEADERS) $(XXXSYNFILES) $(XXXTESTBENCH)
#	 $(VCS) $^ $(LIB) +define+SYNTH_TEST +error+20 -o $(XXX_NAME)_syn_simv

# Function to auto define make xxx and make xxx_verdi_cov commands
define PARTIAL_SYNTHESIS
$($1)_syn:	$($1)_syn_simv
	./$($1)_syn_simv | tee $($1)_syn_program.out
endef

# Defines xxx_syn commands for all modules and stages
$(foreach N,$(COMPONENT_NAMES),$(eval $(call PARTIAL_SYNTHESIS,$N)))

.PHONY: syn


# Debugging-------------------

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

verdi_syn:	syn_simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./syn_simv -gui=verdi

clean:
	rm -rf *simv *simv.daidir csrc vcs.key *program.out *.key *simv.vdb .fsm.sch.verilog.xml
	rm -rf vis_simv vis_simv.daidir test_results.out
	rm -rf dve* inter.vpd DVEfiles
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump *.mem debug_bin
	rm -rf verdi* novas* *fsdb*

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl
