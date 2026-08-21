# MicroBlaze Peripheral UART/GPIO Demo

## Project Purpose

This lab records a board-to-board UART/GPIO communication demo using two Basys3 boards.

- Practice MicroBlaze-based AXI peripheral control.
- Control an AXI Custom UART and AXI GPIO through MMIO.
- Verify UART communication between two Basys3 boards.

## System Configuration

- Master: MicroBlaze + Vitis C sender application
  - Source: `master_vitis_sender/helloworld.c`
  - UART base macro: `XPAR_UART_0_S00_AXI_BASEADDR`
  - GPIOC base macro: `XPAR_GPIO_2_S00_AXI_BASEADDR`
  - GPIOD base macro: `XPAR_GPIO_3_S00_AXI_BASEADDR`
- Slave: Vivado pure RTL UART RX + LED output
  - Source: `slave_rtl_uart_rx/uart_rx_led_top.sv`
  - Constraints: `slave_rtl_uart_rx/slave_uart_rx.xdc`
  - Verified UART baud rate: `115200`

## Connection

- Master TX on `JB1` -> Slave RX on `JB2`
- Master GND -> Slave GND

## Verified Result

- The master LEDs increment according to the transmitted byte value.
- The slave LEDs change according to the received byte value.
- A baud rate mismatch was found and fixed; UART communication then worked normally.

## Key Files

```text
microblaze-uart-gpio/
|-- README.md
|-- docs/
|   `-- uart_gpio_demo.md
|-- master_vitis_sender/
|   `-- helloworld.c
|-- slave_rtl_uart_rx/
|   |-- uart_rx_led_top.sv
|   `-- slave_uart_rx.xdc
`-- notes/
    `-- troubleshooting.md
```

## Next Extensions

- Connect an I2C LCD for live byte/status display.
- Add SPI ADC or sensor input.
- Build an integrated UART/GPIO/I2C peripheral demo.
