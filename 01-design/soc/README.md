# SoC

전용 CPU의 datapath/control 분리에서 시작해 RV32I, bus peripheral, MicroBlaze 기반 SoC로 확장했습니다.

## 학습 흐름

1. [Dedicated CPU](dedicated-cpu/) — counter와 누적 합 연산을 위한 전용 datapath/control 구조
2. [RISC-V RV32I](rv32i/) — Prep, Single Cycle, Multi Cycle, APB integration
3. [AXI Peripherals](axi-peripherals/) — memory-mapped UART, SPI, timer/counter peripheral RTL
4. [MicroBlaze Peripheral SoC](microblaze-peripheral-soc/) — AXI Interconnect, custom peripheral, Vitis firmware 연결

## 주요 Directory

- `dedicated-cpu/` — 특정 기능 중심 CPU 구조
- `rv32i/` — RISC-V architecture progression
- `axi-peripherals/` — AXI peripheral 단위 RTL/TB
- `microblaze-peripheral-soc/` — hardware Tcl/RTL, firmware, bring-up 기록
