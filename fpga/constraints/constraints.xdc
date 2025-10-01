# FPGA Timing Constraints for GEMM Accelerator
# Xilinx Vivado constraints file

# Clock constraints
create_clock -period 10.000 -name clk [get_ports clk]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk]

# Clock uncertainty
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]

# Input/output delays
set_input_delay -clock clk -max 2.0 [get_ports cpu_*]
set_input_delay -clock clk -min 0.5 [get_ports cpu_*]
set_output_delay -clock clk -max 2.0 [get_ports cpu_*]
set_output_delay -clock clk -min 0.5 [get_ports cpu_*]

# Memory interface constraints
set_input_delay -clock clk -max 3.0 [get_ports mem_*]
set_input_delay -clock clk -min 0.5 [get_ports mem_*]
set_output_delay -clock clk -max 3.0 [get_ports mem_*]
set_output_delay -clock clk -min 0.5 [get_ports mem_*]

# False paths
set_false_path -from [get_ports rst_n]
set_false_path -to [get_ports irq_out]

# Multi-cycle paths
set_multicycle_path -setup 2 -from [get_clocks clk] -to [get_clocks clk]
set_multicycle_path -hold 1 -from [get_clocks clk] -to [get_clocks clk]

# MAC array timing
set_max_delay -from [get_pins mac_array_inst/*/mac_inst/clk] -to [get_pins mac_array_inst/*/mac_inst/accum_out] 8.0

# Scratchpad timing
set_max_delay -from [get_pins scratchpad_inst/clk] -to [get_pins scratchpad_inst/rd_data] 6.0
set_max_delay -from [get_pins scratchpad_inst/clk] -to [get_pins scratchpad_inst/wr_ready] 6.0

# DMA timing
set_max_delay -from [get_pins dma_inst/clk] -to [get_pins dma_inst/dma_done] 10.0

# Power constraints
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# I/O standards
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_*]
set_property IOSTANDARD LVCMOS33 [get_ports mem_*]
set_property IOSTANDARD LVCMOS33 [get_ports irq_out]

# Drive strength
set_property DRIVE 12 [get_ports cpu_*]
set_property DRIVE 12 [get_ports mem_*]

# Slew rate
set_property SLEW SLOW [get_ports cpu_*]
set_property SLEW SLOW [get_ports mem_*]

# Pull-up resistors
set_property PULLUP TRUE [get_ports rst_n]

# Timing exceptions for specific paths
set_false_path -through [get_pins mac_array_inst/pipeline_stage*]
set_false_path -through [get_pins dma_inst/state*]

# Clock gating constraints
set_clock_gating_check -setup 0.5 -hold 0.1 [get_clocks clk]

# Maximum fanout
set_max_fanout 100 [get_nets clk]
set_max_fanout 50 [get_nets rst_n]

# Area constraints
set_property MAX_FANOUT 100 [get_cells mac_array_inst]
set_property MAX_FANOUT 50 [get_cells scratchpad_inst]

# Optimization constraints
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]

# Implementation constraints
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Power optimization
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

# Debug constraints
set_property MARK_DEBUG true [get_nets mac_enable]
set_property MARK_DEBUG true [get_nets mac_valid_out]
set_property MARK_DEBUG true [get_nets accel_busy]
set_property MARK_DEBUG true [get_nets accel_done]
