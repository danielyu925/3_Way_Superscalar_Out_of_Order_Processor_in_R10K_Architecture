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
├── Makefile
├── README.m
└── Verilog
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


```
