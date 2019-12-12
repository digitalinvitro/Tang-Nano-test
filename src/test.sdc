#Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
#All rights reserved.
#File Title: Timing Constraints file
#GOWIN Version: 1.9.2.01 Beta
#Created Time: 2019-11-30 18:53:08
create_clock -name clk -period 41.667 -waveform {0 20.834} [get_ports {clock}]
#create_clock -name ready -period 41.667 -waveform {0 20.834} [get_ports {serial_rx|ready_inferred_clock}]