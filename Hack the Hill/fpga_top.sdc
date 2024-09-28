## Generated SDC file "bonza_iob.sdc"

## Copyright (C) 1991-2014 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus II License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 14.0.0 Build 200 06/17/2014 SJ Full Version"

## DATE    "Fri Aug 15 14:05:12 2014"

##
## DEVICE  "5AGZME3H2F35C3"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Base Clocks
#**************************************************************
create_clock -name {clk_lvds_i} -period 6.734 [get_ports {clk_lvds_i}]
create_clock -name {gclk0_148m50_i} -period 6.734 [get_ports {gclk0_148m50_i}]
create_clock -name {gclk1_148m50_i} -period 6.734 [get_ports {gclk1_148m50_i}]
create_clock -name {memrefclk_i} -period 8.000 [get_ports {memrefclk_i}]
create_clock -name {egress_refclk_0} -period 6.734 [get_ports {egress_refclk_i}]

#**************************************************************
# Create Generated Clock
#**************************************************************

