#!/bin/bash
# Open the signed-off RV32I layout in KLayout with Innovus-style colours
cd "$(dirname "$0")"
klayout -l innovus.lyp final/RISC_V_Pipeline_Top.gds.gz &
