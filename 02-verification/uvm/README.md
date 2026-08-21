# UVM Verification Labs

작은 DUT에서 UVM component와 TLM 연결을 익힌 뒤 protocol verification으로 확장한 source를 정리합니다.

## 학습 흐름

1. [Hello World](hello-world/) — `uvm_test`와 `run_test()` 기본 구조
2. [Adder](adder/) — Basic Environment에서 Analysis Port/Subscriber 연습으로 확장
3. [RAM](ram/) — Basic Environment에서 layered component와 Functional Coverage로 확장
4. [SPI](../../01-design/protocols/spi/) / [I2C](../../01-design/protocols/i2c/) — serial protocol Master/Slave verification
5. [AXI4-Lite SPI](../../01-design/protocols/axi4-lite-spi/) — register access와 passive SPI monitoring 통합

## Methodology Labs

- [Adder UVM](adder/) — Sequence Item, Driver, Monitor, Scoreboard, Analysis Port, Subscriber
- [RAM UVM](ram/) — Agent, Environment, Monitor, Scoreboard, Functional Coverage

## Protocol UVM

Protocol code는 동일 source를 복제하지 않고 Design domain에 둡니다.

- [SPI RTL Design & UVM Verification](../../01-design/protocols/spi/)
- [I2C RTL Design & UVM Verification](../../01-design/protocols/i2c/)
- [AXI4-Lite Controlled SPI — UVM Verification](../../01-design/protocols/axi4-lite-spi/)

## 실행 기록 범위

Basic Adder/RAM과 SPI/I2C/AXI4-Lite SPI는 교육 서버에서 복구한 VCS log가 있습니다. Hello World, Adder Analysis Port, layered RAM은 신뢰할 수 있는 PASS 기록을 현재 확인하지 못했습니다.

현재 Windows 환경에서는 UVM simulation을 다시 실행하지 않았습니다.
