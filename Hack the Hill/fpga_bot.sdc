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

#set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Base Clocks
#**************************************************************
#This has to come after ddr IP or some of the clock grouping below won't work.
derive_pll_clocks -create_base_clocks

#**************************************************************
# Create Generated Clock
#**************************************************************


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay  -clock altera_reserved_tck 5 [get_ports altera_reserved_tdi]
set_input_delay  -clock altera_reserved_tck 5 [get_ports altera_reserved_tms]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock altera_reserved_tck 5 [get_ports altera_reserved_tdo]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous \
  -group {altera_reserved_tck \
         } \
  -group {clk125_pll|pll_0|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0] \
         } \
  -group {clk125_pll|pll_0|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
         } \
  -group {clk125_pll|pll_0|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk \
         } \
  -group {clk125_pll|pll_0|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk \
         } \
  -group {clk125_pll|pll_0|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk \
         } \
  -group {egress_refclk_0 \
          sdi_tx_phy|*|txclkout \
          sdi_tx_phy|*|clk010g \
          sdi_tx_phy|*|cpulse \
          sdi_tx_phy|*|hfclkp \
          sdi_tx_phy|*|lfclkp \
          sdi_tx_phy|*|pclk[0] \
          sdi_tx_phy|*|pclk[1] \
          sdi_tx_phy|*|pclk[2] \
          sdi_rx_phy|*|clkout \
         } \
  -group {clk_lvds_i \
         } \
  -group {gclk0_148m50_i \
          gclk1_148m50_i \
         } \
  -group {sdi_tx_phy|*|pmatestbussel } \

#**************************************************************
# Set False Path
#**************************************************************
# Ignore global asynchronous reset
set_false_path -from [get_registers {global_reset_gen:global_reset_gen|reset_o}]
set_false_path -from [get_registers {global_reset_gen:global_reset_gen|reset_n_o}]
set_false_path -to [get_registers {*cdc_sync*|sig_d1_mtb}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

# hold should be 1 less than setup for some reason
#set_multicycle_path -from {ultrix_iob:ultrix_iob|tpg_top:tpg_top|ifs_sdi_flop:ifs_sdi_flop_tpg|NORMAL.NORMAL.sdi_f.fmt[*]} -setup 3  
#set_multicycle_path -from {ultrix_iob:ultrix_iob|tpg_top:tpg_top|ifs_sdi_flop:ifs_sdi_flop_tpg|NORMAL.NORMAL.sdi_f.fmt[*]} -hold 2  
set_multicycle_path -from {tpg_top:tpg_top|ifs_sdi_flop:ifs_sdi_flop_tpg|NORMAL.NORMAL.sdi_f.fmt[*]} -setup 3  
set_multicycle_path -from {tpg_top:tpg_top|ifs_sdi_flop:ifs_sdi_flop_tpg|NORMAL.NORMAL.sdi_f.fmt[*]} -hold 2  

#**************************************************************
# Set Maximum Delay
#**************************************************************
# A specialized clock crossing fifo

#**************************************************************
# Set Minimum Delay
#**************************************************************


#**************************************************************
# Set Input Transition
#**************************************************************
