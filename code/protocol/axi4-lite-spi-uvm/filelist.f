+incdir+tb
+incdir+rtl

// DUT RTL
rtl/spi_v1_0_S00_AXI.v
rtl/spi_master.v
rtl/spi_v1_0.v

// Testbench-only SPI slave response model
rtl/spi_slave.sv

// Interfaces
tb/axi_lite_if.sv
tb/spi_if.sv

// UVM classes are included by tb/tb_top.sv through spi_axi_pkg.
// tb/axi_lite_transaction.sv
// tb/axi_lite_sequence.sv
// tb/axi_lite_driver.sv
// tb/axi_lite_monitor.sv
// tb/spi_monitor.sv
// tb/scoreboard.sv
// tb/coverage.sv
// tb/env.sv
// tb/spi_axi_test.sv
tb/tb_top.sv
