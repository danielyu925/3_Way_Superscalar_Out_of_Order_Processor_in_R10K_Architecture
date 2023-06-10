# EECS 470 Computer Architecture

# Overview:
    Out-of-Order R10k Simulator

# Project MileStone 2
We completed the rest modules for R10K. However, we are working on pipeline stage (i.e., Fetch Dispatch Issue 
FU Complete and Retire). 

Currently, we are unable to pass the test.

## Run simulation for each module ( xxx means module name)
```shell
make xxx
```

## Make synthesis for XXX module
```shell
make xxx_syn
```
## Check test coverage for XXX module
```shell
make xxx_verdi_cov
```



# Project MileStone 1

Do not "make" & "make syn" in milestone1. They are reserved for the final pipeline R10K.

We completed the ROB module

## Run simulation for ROB module
```shell
make rob
```

## Make synthesis for ROB module
```shell
make rob_syn
```
## Check test coverage for ROB module
```shell
make rob_verdi_cov
```

# Tentative Final 

## Run
```shell
make
```

### Build Machine Code from Assemble (*.s)

```shell
make assembly SOURCE="path to your_assembly " 
```

### Build Machine Code from C Program (*.c)

```shell
make program SOURCE="path to your_program.c " 
```

## Run all test case
```shell
./auto_test.sh
```

### Run each module testcases
```shell
make "the module name"
```

# Project Structure

```
.
├── ISA.svh
├── Makefile
├── README.md
├── aslinker.lds
├── auto_test.sh
├── crt.s
├── initialnovas.rc
├── linker.lds
├── synth
│   ├── arch.tcl
│   ├── cache.tcl
│   ├── complete_stage.tcl
│   ├── dispatch.tcl
│   ├── fetch.tcl
│   ├── freelist.tcl
│   ├── issue.tcl
│   ├── maptable.tcl
│   ├── pipeline.tcl
│   ├── prf.tcl
│   ├── retire.tcl
│   ├── rob.tcl
│   └── rs.tcl
├── sys_defs.svh
├── test_progs
│   ├── alexnet.c
│   ├── backtrack.c
│   ├── basic_malloc.c
│   ├── bfs.c
│   ├── dft.c
│   ├── fc_forward.c
│   ├── graph.c
│   ├── haha.s
│   ├── insertionsort.c
│   ├── matrix_mult_rec.c
│   ├── mergesort.c
│   ├── mult_no_lsq.s
│   ├── omegalul.c
│   ├── outer_product.c
│   ├── priority_queue.c
│   ├── quicksort.c
│   ├── rv32_btest1.s
│   ├── rv32_btest2.s
│   ├── rv32_copy.s
│   ├── rv32_copy_long.s
│   ├── rv32_evens.s
│   ├── rv32_evens_long.s
│   ├── rv32_fib.s
│   ├── rv32_fib_long.s
│   ├── rv32_fib_rec.s
│   ├── rv32_halt.s
│   ├── rv32_insertion.s
│   ├── rv32_mult.s
│   ├── rv32_parallel.s
│   ├── rv32_saxpy.s
│   ├── sampler.s
│   ├── sort_search.c
│   └── tj_malloc.h
├── testbench
│   ├── arch_testbench.sv
│   ├── complete_testbench.sv
│   ├── dispatch_testbench.sv
│   ├── fetch_testbench.sv
│   ├── freelist_testbench.sv
│   ├── issue_testbench.sv
│   ├── maptable_testbench.sv
│   ├── mem.sv
│   ├── pipe_print.c
│   ├── prf_testbench.sv
│   ├── retire_testbench.sv
│   ├── riscv_inst.h
│   ├── rob_testbench.sv
│   ├── rs_testbench.sv
│   ├── template.sv
│   ├── testbench.sv
│   ├── visual_c_hooks.cpp
│   └── visual_testbench.v
├── tree.txt
└── verilog
    ├── PRF.sv
    ├── ROB.sv
    ├── arch.sv
    ├── complete_stage.sv
    ├── dispatch.sv
    ├── ex_stage.sv
    ├── fetch.sv
    ├── freelist.sv
    ├── icache.sv
    ├── id_stage.sv
    ├── if_stage.sv
    ├── issue.sv
    ├── maptable.sv
    ├── mem_stage.sv
    ├── mult.sv
    ├── pipeline.sv
    ├── ps.sv
    ├── regfile.sv
    ├── retire.sv
    ├── rs.sv
    └── wb_stage.sv

4 directories, 95 files

```


## Reference
Verilog Cheatsheet
- https://www.cl.cam.ac.uk/teaching/1011/ECAD+Arch/files/SystemVerilogCheatSheet.pdf