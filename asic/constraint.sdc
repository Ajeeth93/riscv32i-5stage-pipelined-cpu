# RV32I core - sky130 - 40 MHz

# 1. Clock
create_clock -name clk -period 25.0 -waveform {0.0 12.5} [get_ports clk]
set_clock_latency -source -early 0.10 [get_clocks clk]
set_clock_latency -source -late  0.20 [get_clocks clk]
set_clock_uncertainty -setup 0.25 [get_clocks clk]
set_clock_uncertainty -hold  0.10 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]

# 2. Drive and load
set in_ports [delete_from_list [all_inputs] [get_ports clk]]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 $in_ports
set_load -pin_load 0.03 [all_outputs]

# 3. I/O budgets
set_input_delay  -max 4.0 -clock clk $in_ports
set_input_delay  -min 2.5 -clock clk $in_ports
set_output_delay -max 4.0 -clock clk [all_outputs]
set_output_delay -min 1.0 -clock clk [all_outputs]

# 4. Exceptions
set_false_path -from [get_ports rst]
set_false_path -from [get_ports dmem_ready]

