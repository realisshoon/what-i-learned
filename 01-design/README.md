# Design

기본 RTL부터 Protocol, CPU/SoC, FPGA integration까지 설계 주제별로 정리합니다.

## RTL

- [Adder](rtl/adder/) — Verilog/SystemVerilog adder와 testbench
- [Counter](rtl/counter/) — counter와 clock/tick 기반 제어
- [FSM](rtl/fsm/) — 상태 기반 LED/control logic
- [FIFO](rtl/fifo/) — synchronous FIFO와 directed/class-based TB
- [Memory](rtl/memory/) — RAM/SRAM RTL과 testbench
- [Register](rtl/register/) — register 기본 동작
- [Stopwatch / Watch](rtl/stopwatch-watch/) — tick generator, counter, control/datapath 구성
- [Combinational Logic](rtl/combinational-logic/) — gate와 조합논리 기본 실습

## Protocols

- [UART](protocols/uart/) — TX/RX, loopback, FIFO/ASCII와 Class-based SystemVerilog Verification
- [SPI](protocols/spi/) — Mode 0 Master/Slave RTL과 UVM Verification
- [I2C](protocols/i2c/) — Master/Slave RTL과 UVM Verification
- [AXI4-Lite](protocols/axi4-lite/) — Master/Slave handshake와 custom IP template
- [AXI4-Lite SPI](protocols/axi4-lite-spi/) — AXI register로 제어하는 SPI peripheral과 UVM Verification
- [SPI/I2C FPGA Link](protocols/spi-i2c-fpga-link/) — protocol 선택과 board-to-board 연결 variant

## Peripherals

- [DHT11](peripherals/dht11/) — 단선 sensor timing과 data capture
- [SR04](peripherals/sr04/) — trigger/echo pulse 기반 거리 측정

## SoC

- [Dedicated CPU](soc/dedicated-cpu/) — 특정 연산을 수행하는 datapath/control 구조
- [RISC-V RV32I](soc/rv32i/) — Single Cycle에서 Multi Cycle, APB까지 확장
- [AXI Peripherals](soc/axi-peripherals/) — UART, SPI, timer/counter peripheral RTL
- [MicroBlaze Peripheral SoC](soc/microblaze-peripheral-soc/) — AXI custom peripheral과 firmware 연결

## Integration

- [UART / Sensor / Stopwatch](integration/uart-sensor-stopwatch/) — UART, FIFO, SR04, DHT11, Watch/Stopwatch 통합 RTL
