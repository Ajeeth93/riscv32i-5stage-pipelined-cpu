#!/usr/bin/env bash
# Compile and run the hazard unit UVM testbench with Vivado xsim.
# Usage (from this folder, with Vivado's settings64.sh sourced):
#   ./run_xsim.sh              # 1000 random transactions (default)
#   ./run_xsim.sh 5000         # 5000 random transactions
set -e

NUM_RAND=${1:-1000}
RTL="../RTL Code/HazardUnit.sv"

xvlog -sv -L uvm "$RTL" hazard_if.sv hazard_pkg.sv tb_top.sv
xelab tb_top -L uvm -timescale 1ns/1ps -s hazard_sim
xsim hazard_sim -R \
     -testplusarg UVM_TESTNAME=hazard_test \
     -testplusarg NUM_RAND=${NUM_RAND} \
     -log hazard_sim.log
