## Generated SDC file "MemoryAccessTestbench.sdc"

## Copyright (C) 2019  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 19.1.0 Build 670 09/22/2019 SJ Lite Edition"

## DATE    "Sun Jul 19 10:25:15 2020"

##
## DEVICE  "EP4CE15F17C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk} -period 20.000 -waveform { 10.000 20.000 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {clk} [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.100  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.100  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.300  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.410  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.300  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.410  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.100  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.100  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.300  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.410  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.300  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.410  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clk}] -setup 0.410  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clk}] -hold 0.300  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clk}] -setup 0.410  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clk}] -hold 0.300  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clk}] -setup 0.410  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clk}] -hold 0.300  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clk}] -setup 0.410  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clk}] -hold 0.300  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.100  
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.100  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.100  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.100  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

