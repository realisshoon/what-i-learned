# Bring-up Log

## Stable Success State

The current stable design is a MicroBlaze-based AXI4-Lite SoC with a custom I2C LCD peripheral.

Confirmed behavior:

- The custom `i2c_lcd_axi_0` IP is mapped at `0x44A60000`.
- The LCD module responds at I2C address `0x27`.
- Vitis writes `CR.START` through AXI4-Lite MMIO.
- The RTL performs LCD power wait, initialization, and `HELLO` output.
- Vitis reads `SR = 0x00000002 [DONE]`.

## Hardware Block Structure

```text
Basys3
  |
  +-- MicroBlaze
      |
      +-- AXI Interconnect
          |
          +-- AXI UARTLite
          +-- Custom UART IP
          +-- Custom Timer IP
          +-- Custom GPIO IP x4
          +-- Custom AXI I2C LCD IP
                 |
                 +-- I2C master RTL
                       |
                       +-- PCF8574 I2C LCD
```

## Software Flow

1. Wait for LCD power stabilization.
2. Write `CR.CLR_STATUS`.
3. Write a test value to `DATA`.
4. Write `CR.START`.
5. Poll `SR` until `DONE` or `ACK_ERROR`.
6. Confirm `SR = 0x00000002 [DONE]`.

## RTL Flow

1. Detect `start_pulse` from the AXI slave register block.
2. Run the LCD initialization sequence.
3. Send the PCF8574 byte stream for `HELLO`.
4. Track I2C ACK after address and data phases.
5. Assert `done` when the sequence is complete.
6. Latch `DONE` or `ACK_ERROR` in the AXI status register.

## I2C LCD Notes

- LCD address used for the successful run: `0x27`
- PCF8574 byte mapping: `{D7,D6,D5,D4,BL,EN,RW,RS}`
- I2C clock target in RTL: `100 kHz`
- LCD output sequence includes initialization commands and `H`, `E`, `L`, `L`, `O`.

## STEP 1 GPIO Readiness

The exported BD already contains four custom GPIO IP instances:

- `gpio_0` at `0x44A00000`
- `gpio_1` at `0x44A10000`
- `gpio_2` at `0x44A20000`
- `gpio_3` at `0x44A30000`

Current external GPIO ports are `GPIOA`, `GPIOB`, `GPIOC`, and `GPIOD`. `GPIOC` and `GPIOD` are constrained to the Basys3 LED pins. The current XDC has the switch-bank constraints commented out, while several button pins are mapped through `GPIOB[4:7]` and `reset`.

Recommended next action:

1. Decide which GPIO instance will be used for `SW[7:0]`.
2. Add or remap XDC constraints for `SW[7:0]`.
3. Decide whether buttons should use `GPIOB[4:7]` or a separate GPIO instance.
4. Confirm GPIO direction control in the custom GPIO IP.
5. Write a Vitis GPIO read test before integrating the LCD display path.
