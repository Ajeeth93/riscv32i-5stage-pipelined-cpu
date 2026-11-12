#!/usr/bin/env bash
# Functional gate-level simulation of the routed netlist (unit delays).
set -e
cd "$(dirname "$0")"     # run inside asic/sim so $readmemh finds RISC-Vmem.txt

PDK=$HOME/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A
CELLS=$PDK/libs.ref/sky130_fd_sc_hd/verilog
RUN=../runs/u70

iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls.vvp \
    "$CELLS/primitives.v" "$CELLS/sky130_fd_sc_hd.v" \
    "$RUN/final/nl/RISC_V_Pipeline_Top.nl.v" \
    InstructionMemory.sv DataMemory.sv riscv_soc.sv tb_gls.sv

vvp gls.vvp
