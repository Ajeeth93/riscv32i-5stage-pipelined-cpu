#!/usr/bin/env bash
# SDF-annotated gate-level simulation with CVC.
# Usage: ./run_cvc.sh <corner> <clock period in ns> [run folder name]
#   ./run_cvc.sh none 25               timing models, no SDF delays
#   ./run_cvc.sh max_ss_100C_1v60 18   setup check (slowest corner)
#   ./run_cvc.sh min_ff_n40C_1v95 18   hold check  (fastest corner)
set -e
cd "$(dirname "$0")"

CORNER=${1:-max_ss_100C_1v60}
PERIOD=${2:-25}
RUN_NAME=${3:-RUN_2026-11-12_03-26-50}
RUN=../../runs/$RUN_NAME

# copy the inputs into this folder
cp "$RUN/final/pnl/RISC_V_Pipeline_Top.pnl.v" netlist.v
cp ../RISC-Vmem.txt .

DEFS="+define+USE_POWER_PINS +define+CLK_NS=$PERIOD"
DELAYS=+maxdelays
if [ "$CORNER" != "none" ]; then
    cp "$(ls "$RUN"/final/sdf/"$CORNER"/*.sdf | head -1)" corner.sdf
    DEFS="$DEFS +define+SDF"
    case "$CORNER" in min_*) DEFS="$DEFS +define+MIN_DELAYS"; DELAYS=+mindelays ;; esac
fi

echo "Run: $RUN_NAME   Corner: $CORNER   Clock: $PERIOD ns"
# patched cell library: *_delayed signals driven directly (see patch_delayed.py)
"$HOME/cvc" +interp $DELAYS +change_port_type $DEFS \
    cells/primitives.v cells/sky130_fd_sc_hd_patched.v netlist.v tb_gls_cvc.v < /dev/null \
    2>&1 | tee "cvc_${CORNER}_${PERIOD}ns.log"
