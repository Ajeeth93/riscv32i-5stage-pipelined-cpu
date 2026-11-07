#!/usr/bin/env bash
# Timing gate-level simulation: routed netlist + SDF delays of one corner.
# Usage: ./run_gls_sdf.sh <corner> <clock period in ns>
#   e.g. ./run_gls_sdf.sh max_ss_100C_1v60 25
set -e
cd "$(dirname "$0")"

CORNER=${1:-max_ss_100C_1v60}
PERIOD=${2:-25}

PDK=$HOME/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A
CELLS=$PDK/libs.ref/sky130_fd_sc_hd/verilog
RUN=../runs/RUN_2026-10-30_22-42-44
SDF=$(ls "$RUN/final/sdf/$CORNER/"*.sdf | head -1)

echo "Corner: $CORNER   Clock: $PERIOD ns   SDF: $SDF"

# No -DFUNCTIONAL: use the timing models; -gspecify: honour their delay paths
iverilog -g2012 -gspecify -DCLK_NS=$PERIOD -DSDF_FILE="\"$SDF\"" -o gls_sdf.vvp \
    "$CELLS/primitives.v" "$CELLS/sky130_fd_sc_hd.v" \
    "$RUN/final/nl/RISC_V_Pipeline_Top.nl.v" \
    InstructionMemory.sv DataMemory.sv riscv_soc.sv tb_gls.sv

vvp gls_sdf.vvp 2>&1 | tee "gls_${CORNER}_${PERIOD}ns.log"
