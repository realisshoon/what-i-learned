# I2C RTL Design & UVM Verification

I2C Master/Slave RTL을 구성하고 START/STOP, write/read, ACK/NACK 흐름을 UVM으로 검증했습니다.

## 한눈에 보기

- I2C Master / Slave RTL
- open-drain SDA와 simulation pull-up
- 7-bit slave address
- write/read와 ACK/NACK transaction
- UVM Driver / Monitor / Scoreboard
- Functional Coverage

## RTL Design

Master는 100 MHz 입력 clock과 100 kHz I2C 기본 parameter를 사용하며 quarter-cycle tick으로 SCL/SDA timing을 나눕니다. SDA는 low drive와 release로 표현하고 top-level simulation model에서 pull-up을 연결합니다.

Master/Slave top은 command, transmit/receive data, address match와 ACK 상태를 함께 관찰할 수 있도록 구성했습니다.

## UVM Verification

| Component | 상속 / 역할 |
|---|---|
| `i2c_driver` | `uvm_driver #(i2c_seq_item)` · command/data 구동 |
| `i2c_monitor` | `uvm_component` · bus transaction 관찰 |
| `i2c_agent` | `uvm_agent` · generic `uvm_sequencer` 연결 |
| `i2c_scoreboard` | `uvm_component` · write/read 결과 비교 |
| `i2c_coverage` | `uvm_subscriber #(i2c_seq_item)` · transaction sampling |

## 검증 결과

| 항목 | 복구된 VCS log |
|---|---|
| Transaction | TOTAL 14 / PASS 14 / FAIL 0 |
| Functional Coverage | 100% |
| UVM_ERROR / UVM_FATAL | 0 / 0 |

> 교육 당시 Linux 서버에서 실행한 log를 복구해 확인한 결과입니다. 현재 Windows 환경에서 다시 실행한 결과는 아닙니다.

## Repository Structure

```text
i2c/
├── rtl/          # standalone Master RTL
├── tb/           # directed testbench
├── uvm/          # Master/Slave RTL, UVM TB, Makefile, filelist
└── constraints/  # FPGA pin constraints
```
