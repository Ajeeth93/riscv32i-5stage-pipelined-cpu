# Worst setup paths at the slow corner, split by capture edge.
# Run inside the LibreLane Docker image from the project folder.
set RUN  asic/runs/RUN_2026-11-12_02-56-49/final
set LIB  $::env(HOME)/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib

read_db      $RUN/odb/RISC_V_Pipeline_Top.odb
read_liberty $LIB
read_sdc     asic/constraint.sdc
read_spef    [glob $RUN/spef/max/*.spef]
set_propagated_clock [all_clocks]

puts "\n===== Worst path into RISING-edge flops (full cycle) ====="
report_checks -path_delay max -to [all_registers -rise_clock clk -data_pins] -fields {fanout cap slew} -digits 3

puts "\n===== Worst path into FALLING-edge flops (half cycle, register file) ====="
report_checks -path_delay max -to [all_registers -fall_clock clk -data_pins] -digits 3
