# ============================================================================
# Grouped waveform view for the processor testbench (Vivado simulator)
# Usage: after "Run Behavioral Simulation", in the Tcl console:
#     source {<path-to-repo>/Test Bench/wave.tcl}
# Then File > Save Waveform Configuration to keep it as a .wcfg.
# ============================================================================

set tb /testbench

remove_wave [get_waves *]

# --------------------------------------------------------------- Top level
add_wave                $tb/clk
add_wave                $tb/rst
add_wave -radix hex     $tb/PC
add_wave -radix hex     $tb/Instr
add_wave -radix ascii   $tb/instruction_ascii

# ------------------------------------------------------------- Instruction
set g [add_wave_group Instruction]
add_wave -into $g -radix hex      $tb/instruction
add_wave -into $g -radix bin      $tb/opcode
add_wave -into $g -radix dec      $tb/imm
add_wave -into $g -radix unsigned $tb/rs1
add_wave -into $g -radix unsigned $tb/rs2
add_wave -into $g -radix unsigned $tb/rd

# -------------------------------------------------------------------- Core
set g [add_wave_group Core]
add_wave -into $g                 $tb/lwstall
add_wave -into $g                 $tb/StallF
add_wave -into $g                 $tb/StallD
add_wave -into $g                 $tb/FlushD
add_wave -into $g                 $tb/FlushE
add_wave -into $g -radix bin      $tb/ForwardAE
add_wave -into $g -radix bin      $tb/ForwardBE
add_wave -into $g                 $tb/PCSrcE
add_wave -into $g -radix dec      $tb/ALUResultE
add_wave -into $g                 $tb/RegWriteW
add_wave -into $g -radix unsigned $tb/RdW
add_wave -into $g -radix dec      $tb/ResultW
add_wave -into $g                 $tb/MemWrite
add_wave -into $g -radix dec      $tb/DataAdr
add_wave -into $g -radix dec      $tb/WriteData

# --------------------------------------------------------------- Registers
set g [add_wave_group Registers]
foreach r {ra sp gp tp t0 t1 t2 s0 s1} {
    add_wave -into $g -radix dec $tb/$r
}

restart
run all
