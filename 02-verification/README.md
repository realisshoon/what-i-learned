# Verification

Class-based SystemVerilog Verification부터 UVM 기반 Protocol Verification까지 단계적으로 진행한 내용을 정리합니다.

## Verification 방식

### Directed Testbench

RTL 입력과 예상 동작을 testbench에서 직접 기술하고 waveform과 출력값을 확인했습니다. 기본 RTL, peripheral, AXI4-Lite 실습에 사용했습니다.

### Class-based SystemVerilog Verification

UVM library 없이 Transaction, Generator, Driver, Monitor, Scoreboard와 Mailbox를 직접 구성했습니다. [UART](../01-design/protocols/uart/)와 [SystemVerilog OOP labs](systemverilog/)에서 확인할 수 있습니다.

### UVM Verification

Sequence Item, Sequence, Driver, Monitor, Scoreboard, Analysis Port와 Functional Coverage를 단계적으로 적용했습니다. Protocol DUT source는 domain directory에 함께 보관합니다.

## UVM 학습 흐름

1. Hello World
2. Adder / RAM Basic Environment
3. Analysis Port / Subscriber
4. Layered RAM + Coverage
5. SPI / I2C Protocol Verification
6. AXI4-Lite + SPI Integration Verification

[UVM Methodology Labs 보기](uvm/)

## UVM 적용 Project

- [SPI RTL Design & UVM Verification](../01-design/protocols/spi/)
- [I2C RTL Design & UVM Verification](../01-design/protocols/i2c/)
- [AXI4-Lite Controlled SPI — UVM Verification](../01-design/protocols/axi4-lite-spi/)

## 복구된 Verification Result

| 대상 | 확인된 결과 |
|---|---|
| SPI | PASS 48 / FAIL 0, Functional Coverage 59.59% |
| I2C | TOTAL 14 / PASS 14 / FAIL 0, Functional Coverage 100% |
| AXI4-Lite SPI | PASS 32 / FAIL 0, Functional Coverage 100% |

> 수치는 교육 당시 Linux 서버의 VCS simulation log에서 복구한 기록입니다. 현재 Windows 환경에서 다시 실행한 결과는 아닙니다.
