#!/bin/bash

###########################################################
# Auto Tester
###########################################################

DIR=./

#FILES[0]=/home/yanruj/Desktop/project3/test_progs/sampler.s
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

make nuke
rm -rf ${DIR}/test_output/*
#rm -rf ${DIR}/ground_output/*


for file in test_progs/*; do
#    file=$(echo $file | cut -d'.' -f1)
    echo "Assembling $file"
#    echo "$(basename $file).s"
   #----Part1---------------------------------------#
   #assemble the testcase (*.c, *.s) to machine mode
#    # How do you assemble a testcase?

    if [ "${file: -2}" == ".s" ]; then
        make assembly SOURCE=test_progs/$(basename $file)
    elif [ "${file: -2}" == ".c" ]; then
        make program SOURCE=test_progs/$(basename $file)
    fi

    file=$(echo $file | cut -d'.' -f1)



##    assemble
#    riscv gcc -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align $(basename $file).s -T aslinker.lds -o program.elf
#    cp program.elf program.debug.elf
##   disassemble
#    riscv objcopy --set-section-flags .bss=contents,alloc,readonly program.debug.elf
#    riscv objdump -SD -M no-aliases  program.debug.elf > program.dump
#    riscv objdump -SD -M numeric,no-aliases program.debug.elf > program.debug.dump
##   hex
#    riscv elf2hex 8 8192 program.elf > program.mem
#    cp program.mem test_output/program.mem

    #----Part2---------------------------------------#
    #run testcase
    echo "Running $file"
    # How do you run a testcase?
    echo "Running the testcase $(basename $file)"
    make > /dev/null 2>&1


    #----Part3---------------------------------------#
    #Save output files
    # How do you want to save the output? # What files do you want to save?

    echo "Saving $file output"
    mv writeback.out test_output/$(basename $file)_writeback.out
    cat program.out | grep "@@@" > test_output/$(basename $file)_program.out
    mv pipeline.out test_output/$(basename $file)pipeline.out

#    Similarly for ground truth
#    echo "Running the ground truth for testcase $(basename $file)"
#    make > /dev/null 2>&1
#    mv writeback.out ground_output/$(basename $file)_writeback.out
#    cat program.out | grep "@@@" > ground_output/$(basename $file)_program.out

    make clean
    #----Part4---------------------------------------#


    diff ${DIR}/test_output/$(basename $file)_writeback.out ${DIR}/ground_output/$(basename $file)_writeback.out
    exit_status=$?
    if [ $exit_status -eq 1 ]; then
        echo -e " ${RED}@@@Failed${NC} "
    else
        echo -e " ${GREEN}@@@SUCCEED${NC} "
    fi

    diff ${DIR}/test_output/$(basename $file)_program.out ${DIR}/ground_output/$(basename $file)_program.out
    exit_status=$?
    if [ $exit_status -eq 1 ]; then
        echo -e " ${RED}@@@Failed${NC} "
    else
        echo -e " ${GREEN}@@@SUCCEED${NC} "
    fi

    make nuke > /dev/null 2>&1



done

#https://devhints.io/bash