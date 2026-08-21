# SPI RTL Design & UVM Verification

SPI Mode 0 Master/Slave RTL을 설계하고 UVM 기반 self-checking 환경을 구성했습니다.

## 한눈에 보기

- 8-bit SPI Master / Slave RTL
- Mode 0: CPOL=0, CPHA=0
- MSB-first full-duplex transfer
- UVM Driver / Monitor / Scoreboard
- Functional Coverage
- VCS simulation / FSDB waveform

## RTL Design

Master는 `CS_N`과 분주한 `SCLK`를 생성합니다. MOSI 첫 bit를 transaction 시작 시점에 미리 출력하고, rising edge에서 MISO를 sampling하며 falling edge에서 다음 MOSI bit를 갱신합니다.

Slave는 동기화한 `SCLK`와 `CS_N` edge를 감지합니다. rising edge에서 MOSI를 받고 falling edge에서 다음 MISO bit를 준비합니다.

## UVM Verification

`spi_agent`라는 component가 sequencer, driver, monitor를 생성하고 연결합니다. class 이름은 agent이지만 `uvm_agent`가 아닌 `uvm_component`를 상속합니다.

| Component | 상속 / 역할 |
|---|---|
| `spi_driver` | `uvm_driver #(spi_seq_item)` · transaction 구동 |
| `spi_monitor` | `uvm_component` · 완료 transaction 관찰 |
| `spi_agent` | `uvm_component` · generic `uvm_sequencer` 연결 |
| `spi_scoreboard` | `uvm_component` · Master/Slave 송수신 값 비교 |
| `spi_coverage` | `uvm_subscriber #(spi_seq_item)` · transaction sampling |

## 검증 결과

| 항목 | 복구된 VCS log |
|---|---|
| Scoreboard | PASS 48 / FAIL 0 |
| Functional Coverage | 59.59% |
| UVM_ERROR / UVM_FATAL | 0 / 0 |

> 교육 당시 Linux 서버에서 실행한 log를 복구해 확인한 결과입니다. 현재 Windows 환경에서 다시 실행한 결과는 아닙니다.

## Repository Structure

```text
spi/
├── rtl/       # standalone Master/Slave RTL
├── tb/        # directed testbench
├── uvm/       # UVM용 RTL, testbench, Makefile, filelist
└── docs/      # 학습 기록
```
