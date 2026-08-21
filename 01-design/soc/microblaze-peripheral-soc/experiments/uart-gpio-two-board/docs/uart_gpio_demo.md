# UART/GPIO Demo

## Overall Block Structure

```text
Master Basys3
  MicroBlaze
    -> AXI Custom UART
       -> UART TX pin on JB1
    -> AXI GPIOC/GPIOD
       -> local LED monitor

Slave Basys3
  RX pin on JB2
    -> uart_rx_led_top.sv
       -> GPIOC[7:0] received-byte LED display
       -> GPIOD[0] receive-event toggle
```

## Master Operation Flow

1. Configure GPIOC and GPIOD as output ports.
2. Start the transmit byte at `0x55`.
3. Poll UART status register bit 0, `TX_READY`.
4. Write one byte to the UART TDR register.
5. Display the same transmitted value on GPIOC/GPIOD LEDs.
6. Increment the transmit byte and repeat.

The Vitis application uses MMIO directly through `Xil_In32` and `Xil_Out32`.

## Slave Operation Flow

1. Synchronize the external UART RX signal into the `sys_clock` domain.
2. Detect a low start bit.
3. Sample 8 UART data bits LSB-first.
4. Wait through the stop bit.
5. Latch the received byte.
6. Display the received byte on `GPIOC[7:0]`.
7. Toggle `GPIOD[0]` for each receive event.

## UART Frame Concept

This demo uses the common 8N1 UART frame:

- 1 start bit: low
- 8 data bits: LSB first
- No parity bit
- 1 stop bit: high

The receiver samples near the middle of each bit period. Because UART has no shared clock, the master and slave baud rates must match closely.

## Baud Rate Mismatch Troubleshooting

During bring-up, the slave saw receive activity, but the LED data did not match the transmitted byte. That pointed to a timing mismatch rather than a completely disconnected wire.

The fix was to align the master and slave UART settings. The final verified slave RTL parameter is:

```systemverilog
parameter int BAUD_RATE = 115_200
```

After rebuilding the slave RTL bitstream with the corrected baud rate, the slave LEDs followed the transmitted byte stream.

## Success Check

- Master GPIOC/GPIOD LEDs increment as the sender byte increases.
- Slave GPIOC LEDs change according to the received byte.
- Slave GPIOD bit 0 toggles on each received byte.
- Verification does not require PC USB-UART terminal output.

## Future I2C LCD Plan

The next extension is to add an I2C LCD status display:

1. Add an AXI I2C controller or a lightweight I2C master.
2. Display the current TX/RX byte on the LCD.
3. Add simple link status messages.
4. Combine UART, GPIO, and I2C into one integrated peripheral demo.
