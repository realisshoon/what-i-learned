# AXI4-Lite Controlled SPI — UVM Verification

AXI4-Lite register로 제어하는 SPI peripheral을 구성하고 IP level UVM 환경에서 register access와 serial transaction을 함께 확인했습니다.

## 한눈에 보기

- AXI4-Lite slave register interface
- SPI Master DUT와 SPI Slave response model
- AXI active stimulus / monitoring
- SPI passive monitoring
- UVM Scoreboard와 4개 Functional Coverage group
- VCS / Verdi / URG build target

## Architecture

AXI path에서는 Driver가 register write/read transaction을 DUT에 전달하고 AXI Monitor가 handshake 결과를 수집합니다. SPI path에서는 별도 Driver 없이 `spi_monitor`가 MOSI/MISO byte를 복원합니다.

[UVM architecture source 열기](assets/uvm-architecture.drawio)

Diagram의 “SPI Agent” 표기는 passive monitoring path를 묶어 표현한 개념입니다. 실제 code에는 explicit SPI agent class가 없습니다.

## RTL

DUT는 `spi_v1_0`, `spi_v1_0_S00_AXI`, `spi_master`로 구성합니다. `spi_slave`는 DUT가 아니라 testbench response model입니다.

| Offset | Register | 주요 field |
|---|---|---|
| `0x00` | CR | bit0 START, bit1 CLR_STATUS, bit15:8 CLK_DIV |
| `0x04` | TXDATA | bit7:0 transmit data |
| `0x08` | RXDATA | bit7:0 receive data |
| `0x0C` | SR | bit0 BUSY, bit1 DONE |

## UVM Verification

- `axi_lite_driver`는 `uvm_driver #(axi_lite_transaction)`를 상속합니다.
- `axi_lite_monitor`와 `spi_monitor`는 `uvm_component`를 상속합니다.
- `scoreboard`는 AXI TX/RX register data와 SPI monitor가 복원한 byte를 비교합니다.
- `spi_axi_coverage`는 `uvm_component`이며 내부 TLM FIFO로 AXI/SPI transaction을 받습니다.

## Functional Coverage

`TXDATA`, START write, DONE status, SPI transaction complete를 각각 covergroup으로 sampling합니다. Code coverage target은 `scripts/cov_hier.cfg`로 DUT hierarchy에 제한합니다.

## 검증 결과

| 항목 | 복구된 VCS log |
|---|---|
| Scoreboard | PASS 32 / FAIL 0 |
| Functional Coverage | TOTAL 100% |
| UVM_ERROR / UVM_FATAL | 0 / 0 |

> 교육 당시 Linux 서버에서 실행한 log를 복구해 확인한 결과입니다. 현재 Windows 환경에서 다시 실행한 결과는 아닙니다.

## Simulation / Debug

- `make sim` — VCS compile과 UVM simulation
- `make cov` — functional/code coverage 실행
- `make verdi` / `make vdcov` — waveform과 coverage 확인
- `make urg` — coverage report 생성

## Repository Structure

```text
axi4-lite-spi/
├── rtl/       # AXI4-Lite SPI peripheral RTL
├── tb/        # interface와 top-level testbench
├── uvm/       # sequence, driver, monitors, scoreboard, coverage
├── scripts/   # coverage hierarchy 설정
├── assets/    # Draw.io architecture source
└── docs/      # 학습 및 debug 기록
```
