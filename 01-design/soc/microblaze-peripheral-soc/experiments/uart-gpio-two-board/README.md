# MicroBlaze Peripheral UART/GPIO Demo

두 대의 Basys3 board를 UART로 연결하고 송수신 byte를 LED로 확인한 실습입니다.

## 한눈에 보기

- Master: MicroBlaze + Vitis C sender
- Slave: pure RTL UART RX + LED output
- AXI custom UART/GPIO MMIO access
- 115200 baud board-to-board communication

## System 구성

Master application은 custom UART register에 byte를 쓰고 GPIO LED에도 같은 값을 표시합니다. Slave RTL은 PMOD로 들어온 UART frame을 수신해 LED에 출력합니다.

- Master TX `JB1` → Slave RX `JB2`
- Master GND → Slave GND

## 확인 기록

- Master LED가 transmit byte에 따라 증가했습니다.
- Slave LED가 receive byte에 따라 바뀌었습니다.
- baud rate mismatch를 수정한 뒤 두 board 사이 UART 동작을 확인했습니다.

## Repository Structure

```text
uart-gpio-two-board/
├── master_vitis_sender/  # MicroBlaze sender application
├── slave_rtl_uart_rx/    # UART RX/LED RTL과 constraints
├── docs/                 # 연결 및 동작 기록
└── notes/                # troubleshooting
```

- [구성 및 동작 기록](docs/uart_gpio_demo.md)
- [Troubleshooting](notes/troubleshooting.md)
