# MicroBlaze Multi-Peripheral Communication SoC

Basys3-based MicroBlaze SoC project for designing AXI4-Lite custom peripherals and displaying peripheral status on an I2C LCD.

## Current Status

This snapshot preserves the stable version where the custom AXI I2C LCD peripheral successfully initializes a PCF8574-based I2C LCD and prints `HELLO`.

Completed features:

- MicroBlaze block design bring-up
- AXI4-Lite custom I2C LCD IP design
- I2C master RTL integration
- PCF8574-based I2C LCD ACK verification
- LCD initialization sequence
- `HELLO` output on the LCD
- AXI register control and status read from Vitis

## System Configuration

- Board: Basys3
- Processor: MicroBlaze
- Hardware control path: AXI4-Lite MMIO
- Custom peripheral: `i2c_lcd_axi_0`
- Vitis application: `sw/vitis/i2c_lcd_hello/src/main.c`
- I2C LCD address: `0x27`
- I2C LCD base address: `0x44A60000`

## I2C LCD IP Register Map

| Offset | Register | Bit fields |
| --- | --- | --- |
| `0x00` | `CR` | bit0 `START`, bit1 `CLR_STATUS` |
| `0x04` | `DATA` | `[31:0]` data register |
| `0x08` | `SR` | bit0 `BUSY`, bit1 `DONE`, bit2 `ACK_ERROR` |
| `0x0C` | `RESERVED` | reserved |

Confirmed values:

- `I2C_LCD_BASE = 0x44A60000`
- `LCD_ADDR = 0x27`
- Success log: `SR = 0x00000002 [DONE]`

## Repository Contents

- `hw/vivado/bd/design_1.tcl`: exported block design Tcl snapshot
- `hw/vivado/constraints/basys3.xdc`: Basys3 pin constraints used by the design
- `hw/vivado/ip_repo/i2c_lcd_axi_1.0/hdl/`: custom AXI I2C LCD RTL
- `sw/vitis/i2c_lcd_hello/src/main.c`: Vitis test application that writes `START` and polls `SR`
- `docs/bringup_log.md`: hardware/software bring-up notes
- `docs/register_map.md`: register and address notes

Vivado and Vitis generated outputs are intentionally excluded.

## Next Development Plan

1. Read `SW[7:0]` and `BTN` inputs through AXI GPIO.
2. Display switch values on the LCD.
3. Display AXI Timer values on the LCD.
4. Send values to a slave board through UART.
5. Display received values on the slave board LED/FND.
6. Add an AXI SPI peripheral.
7. Integrate `BTN0=UART`, `BTN1=SPI`, and `BTN2=Timer LCD` display modes.
