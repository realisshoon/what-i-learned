# UART RTL & Class-based SystemVerilog Verification

UART TX/RX RTL에서 시작해 loopback, FIFO, ASCII 변환과 class-based self-checking testbench까지 확장했습니다.

## 한눈에 보기

- UART TX / RX와 baud tick generator
- start, 8-bit data, stop bit frame
- loopback RTL
- RX FIFO와 ASCII decode/encode
- Class-based SystemVerilog Verification
- Vivado constraints와 directed TB

## RTL

`uart.v`와 `uart_sv.sv`에 TX, RX, baud tick generator를 구성했습니다. 별도 top에서 loopback과 RX FIFO를 연결하고 ASCII 입력/출력 경로를 추가했습니다.

## Verification

Directed TB로 byte 전송, TX bit count, loopback을 확인하는 흐름을 보존합니다. 이후 SystemVerilog TB에서 다음 component를 직접 구성했습니다.

- Transaction과 constrained randomization
- Generator / Driver / Monitor / Scoreboard
- parameterized Mailbox와 event synchronization
- virtual interface를 통한 DUT signal access

이 환경은 UVM library를 사용하지 않는 Class-based SystemVerilog Verification입니다.

## Repository Structure

```text
uart/
├── rtl/          # UART, loopback, FIFO, ASCII RTL
├── tb/           # Directed / Class-based SystemVerilog Verification
├── constraints/  # Basys3 constraints
└── docs/         # UART와 UART+FIFO 학습 기록
```

## 현재 상태

초기 Verilog TB 일부는 `btnR` port를 참조하지만 현재 보존된 `uart` top과 revision이 맞지 않습니다. 해당 source는 임의로 수정하지 않았으며 이후 SystemVerilog RTL/TB는 별도 파일로 보존합니다.
