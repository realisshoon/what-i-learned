# AXI4-Lite SPI UVM

IP-level UVM verification environment for the `spi_v1_0` AXI4-Lite SPI peripheral.

## Scope
- DUT: `spi_v1_0`, `spi_v1_0_S00_AXI`, `spi_master`
- Testbench response model: `spi_slave`
- Excludes MicroBlaze and full SoC verification

## Register Map
- `0x00 CR`: bit0 START, bit1 CLR_STATUS, bit15:8 CLK_DIV
- `0x04 TXDATA`: bit7:0 TX data
- `0x08 RXDATA`: bit7:0 RX data
- `0x0C SR`: bit0 BUSY, bit1 DONE

## Run
```sh
make sim
```

## Waveform
```sh
make verdi
```

## Coverage
```sh
make cov
make vdcov
make urg
```

Coverage is filtered to the DUT hierarchy through `cov_hier.cfg` so UVM/Verdi recorder code does not pollute the DUT code coverage score.

## Useful Verdi Signals
- `tb_top.axi_bus.*`
- `tb_top.spi_bus.cs_n`
- `tb_top.spi_bus.sclk`
- `tb_top.spi_bus.mosi`
- `tb_top.spi_bus.miso`
- `tb_top.dut.spi_v1_0_S00_AXI_inst.done_sticky`
- `tb_top.dut.spi_v1_0_S00_AXI_inst.slv_reg0`
- `tb_top.dut.spi_v1_0_S00_AXI_inst.slv_reg1`
