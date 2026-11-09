# -----------------------------------------------------------------------------
# File: constraints/kuidamos_pixel_frontend.sdc
# Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M8)
# Description:
#   Synopsys Design Constraints (SDC) for kuidamos_pixel_frontend.
#   Reference clock target from docs/spec_v1.md §11: 100 MHz (10.0 ns).
# -----------------------------------------------------------------------------

if {![info exists CLOCK_PERIOD_NS]} {
    set CLOCK_PERIOD_NS 10.0
}

# 1. Primary Clock Definition (100 MHz / 10.0 ns default)
create_clock -name clk -period $CLOCK_PERIOD_NS [get_ports clk]

# 2. Clock Uncertainty and Transition
set_clock_uncertainty -setup 0.20 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]
set_clock_transition  0.10 [get_clocks clk]

# 3. Synchronous Input and Output Delays (20% of clock period max, 0.20 ns min)
set non_clk_inputs [remove_from_collection [all_inputs] [get_ports clk]]
set io_max_delay   [expr {0.20 * $CLOCK_PERIOD_NS}]

set_input_delay  -max $io_max_delay -clock clk $non_clk_inputs
set_input_delay  -min 0.20          -clock clk $non_clk_inputs

set_output_delay -max $io_max_delay -clock clk [all_outputs]
set_output_delay -min 0.20          -clock clk [all_outputs]

# 4. Electrical Boundary Conditions (Input Transition & Output Load)
#    Library units in saed32rvt_ss0p95v125c.db: Time = 1 ns, Capacitance = 1 fF.
#    - set_input_transition 0.15 -> 0.15 ns
#    - set_load 0.05             -> 0.05 fF
set_input_transition 0.15 $non_clk_inputs
set_load             0.05 [all_outputs]
