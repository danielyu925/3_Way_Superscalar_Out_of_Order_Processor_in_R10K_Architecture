#!/bin/bash
# A script meant to make testing multiple modules easier
# Just uncomment the ones you want to test and run ./test.sh

#make nuke

# TEST STAGES
#make complete
#make complete_syn
#make dispatch
#make dispatch_syn
#make fetch
#make fetch_syn
#make issue
#make issue_syn
#make retire
#make retire_syn

# TEST MODULES
#make arch
#make arch_syn
#make freelist
#make freelist_syn
#make fu
#make fu_syn
#make maptable
#make maptable_syn
#make rs
#make rs_syn
#make rob 
#make rob_syn 

# TEST MEMORY
#make icache
#make icache_syn
#make prf
#make prf_syn

# TEST CONNECTIONS
#make dispatch_fetch_freelist
#make dispatch_fetch_freelist_syn
#make dispatch_fetch_rs
#make dispatch_fetch_rs_syn
#make dispatch_fetch
#make dispatch_fetch_syn
#make dispatch_freelist
#make dispatch_freelist_syn
#make dispatch_maptable
#make dispatch_maptable_syn
#make dispatch_rob
#make dispatch_rob_syn
#make dispatch_rs
#make dispatch_rs_syn
#make fu_complete
#make fu_complete_syn
#make retire_rob_arch_freelist
#make retire_rob_arch_freelist_syn

# TEST PIPELINE
#make assembly SOURCE=test_progs/rv32_halt.s
#make assembly SOURCE=test_progs/mult_no_lsq.s
make assembly SOURCE=test_progs/rv32_btest1.s
make pipeline
#make syn