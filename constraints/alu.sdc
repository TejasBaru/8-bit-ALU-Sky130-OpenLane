##################################################################################################################


# Clock definition
create_clock -name clk -period 10.0 [get_ports clk]

# Set Input Delay
set_input_delay 2.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk] ]

# Set Output Delay
set_output_delay 2.0 -clock clk [all_outputs]

# Set Maximum transition 
set_max_transition 1.5 [current_design]

# Set Max FanOut
set_max_fanout 4 [current_design]

