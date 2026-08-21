## Minimal Basys3 constraints for slave UART RX LED demo

## Clock: 100 MHz system clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports sys_clock]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports sys_clock]

## Reset button
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

## UART RX input: JB2
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports rx]

## GPIOC LEDs: received byte
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {GPIOC[7]}]

## GPIOD LEDs: receive-event indicator
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {GPIOD[0]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[1]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[2]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[3]}]
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[4]}]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[5]}]
set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[6]}]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports {GPIOD[7]}]
