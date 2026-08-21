# Protocols

serial protocol RTL에서 시작해 memory-mapped peripheral과 protocol integration으로 확장한 학습 흐름입니다.

1. [UART](uart/) — TX/RX와 baud tick을 구현하고 loopback, FIFO, ASCII 경로를 Directed TB와 Class-based SystemVerilog Verification으로 확인했습니다.
2. [SPI](spi/) — Mode 0 Master/Slave RTL을 구성하고 UVM Driver, Monitor, Scoreboard, Functional Coverage를 적용했습니다.
3. [I2C](i2c/) — open-drain SDA, START/STOP, ACK/NACK를 포함한 Master/Slave 구조를 UVM으로 검증했습니다.
4. [AXI4-Lite](axi4-lite/) — AW/W/B와 AR/R channel의 VALID/READY handshake를 Master/Slave RTL로 구현했습니다.
5. [AXI4-Lite Controlled SPI](axi4-lite-spi/) — AXI4-Lite register access와 SPI serial transaction을 하나의 UVM Scoreboard에서 비교했습니다.

## Integration Variant

- [SPI/I2C FPGA Link](spi-i2c-fpga-link/) — SPI와 I2C의 master/slave 및 top-level 연결 variant를 보존합니다.

Protocol UVM source는 각 protocol directory에 두고, [Verification Index](../../02-verification/)에서는 링크로 연결합니다.
