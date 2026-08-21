# On-Device AI Semiconductor Labs

온디바이스 AI 시스템반도체 설계 교육 과정에서 진행한
RTL Design, SystemVerilog/UVM Verification, SoC, Embedded Firmware 실습을 정리한 저장소입니다.

기초 RTL부터 Protocol Verification, RISC-V/SoC, Embedded Firmware까지
직접 구현한 코드와 검증 과정을 기술 주제별로 정리했습니다.

## 주요 학습 영역

| 영역 | 내용 |
|---|---|
| Design | Verilog/SystemVerilog RTL, FSM, FIFO, Memory, UART, SPI, I2C, AXI4-Lite, RISC-V |
| Verification | SystemVerilog OOP, Class-based SystemVerilog Verification, UVM, Scoreboard, Functional Coverage |
| Embedded | STM32F411 Bare-metal C, MicroBlaze/Vitis firmware, MMIO 기반 peripheral control |

## Repository 구성

- [Design](01-design/) — RTL, Protocol, CPU/SoC, FPGA integration
- [Verification](02-verification/) — SystemVerilog OOP와 UVM methodology lab
- [Embedded](03-embedded/) — STM32F411 Bare-metal firmware
- [Tools](tools/) — Vivado, Vitis, VCS, Verdi 사용 범위

## 주요 학습 내용

### Protocol Design & Verification

- [UART](01-design/protocols/uart/) — TX/RX, loopback, FIFO/ASCII 연동과 Class-based SystemVerilog Verification
- [SPI](01-design/protocols/spi/) — Mode 0 Master/Slave RTL과 UVM Verification
- [I2C](01-design/protocols/i2c/) — Master/Slave RTL, ACK/NACK 처리와 UVM Verification
- [AXI4-Lite](01-design/protocols/axi4-lite/) — Master/Slave RTL과 VALID/READY handshake
- [AXI4-Lite Controlled SPI](01-design/protocols/axi4-lite-spi/) — memory-mapped SPI peripheral과 UVM Verification

### CPU / SoC

- [Dedicated CPU](01-design/soc/dedicated-cpu/) — 전용 datapath/control 구조 실습
- [RISC-V RV32I](01-design/soc/rv32i/) — Prep, Single Cycle, Multi Cycle, APB integration
- [AXI Peripherals](01-design/soc/axi-peripherals/) — UART, SPI, timer/counter peripheral RTL
- [MicroBlaze Peripheral SoC](01-design/soc/microblaze-peripheral-soc/) — AXI custom peripheral과 Vitis C application

### Verification

- [SystemVerilog Verification](02-verification/systemverilog/) — OOP와 Class-based SystemVerilog Verification
- [UVM Methodology Labs](02-verification/uvm/) — Hello World, Adder, RAM, Analysis Port, Coverage
- [SPI UVM](01-design/protocols/spi/), [I2C UVM](01-design/protocols/i2c/), [AXI4-Lite SPI UVM](01-design/protocols/axi4-lite-spi/) — domain별 protocol verification

### Embedded

- [STM32F411 Timer/UART Labs](03-embedded/firmware/stm32f411/timer-uart-labs/) — register-level Timer, UART, GPIO 제어

## Skill Matrix

| 분야 | 학습/구현 내용 | 검증 방식 |
|---|---|---|
| RTL | FSM, FIFO, RAM, Counter, Stopwatch | Directed / SystemVerilog TB |
| UART | TX/RX, baud tick, loopback, FIFO, ASCII | Directed + Class-based SystemVerilog Verification |
| SPI | Mode 0 Master/Slave RTL | UVM, Scoreboard, Functional Coverage |
| I2C | Master/Slave RTL, open-drain SDA, ACK/NACK | UVM, Scoreboard, Functional Coverage |
| [AXI4-Lite](01-design/protocols/axi4-lite/) | Master/Slave, VALID/READY handshake | SystemVerilog TB |
| [AXI4-Lite SPI](01-design/protocols/axi4-lite-spi/) | Memory-mapped SPI peripheral | UVM, Scoreboard, Functional Coverage |
| RISC-V | RV32I Single/Multi Cycle, APB integration | SystemVerilog TB |
| Embedded | STM32F411, MicroBlaze C | Firmware/board lab |

## Verification Highlights

| 대상 | 검증 | 복구된 실행 기록 |
|---|---|---|
| SPI | UVM | PASS 48 / FAIL 0 · Functional Coverage 59.59% |
| I2C | UVM | PASS 14 / FAIL 0 · Functional Coverage 100% |
| AXI4-Lite SPI | UVM | PASS 32 / FAIL 0 · Functional Coverage 100% |

> 위 결과는 교육 당시 Linux 서버에서 실행한 VCS simulation log를 복구해 확인한 기록입니다. 현재 Windows repository 환경에서 다시 실행한 결과는 아닙니다.

각 Topic README에는 RTL/UVM 구조와 현재 보존 상태를 source 기준으로 기록했습니다.
