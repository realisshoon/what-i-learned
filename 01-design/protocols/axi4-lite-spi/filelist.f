+incdir+tb
+incdir+rtl
+incdir+uvm

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
// uvm/axi_lite_transaction.sv
// uvm/axi_lite_sequence.sv
// uvm/axi_lite_driver.sv
// uvm/axi_lite_monitor.sv
// uvm/spi_monitor.sv
// uvm/scoreboard.sv
// uvm/coverage.sv
// uvm/env.sv
// uvm/spi_axi_test.sv
tb/tb_top.sv
