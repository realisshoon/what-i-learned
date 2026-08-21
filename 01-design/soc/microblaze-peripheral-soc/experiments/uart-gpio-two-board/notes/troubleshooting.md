# Troubleshooting Notes

## Two-board Vitis Target Selection

When both boards were connected, the MicroBlaze targets could appear with similar names in Vitis. This made it easy to select the wrong execution target.

The working split was:

- Master board: run the MicroBlaze sender application from Vitis.
- Slave board: do not use Vitis; program only the Vivado RTL bitstream.

This keeps the master software flow and the slave RTL-only flow separate.

## UART Baud Rate Mismatch

Symptom:

- The slave detected receive events.
- `GPIOD[0]` could toggle, but `GPIOC[7:0]` showed incorrect byte values.

Cause:

- The transmitter and receiver baud rates were not matched.

Fix:

- Set the slave RTL UART receiver to the final verified baud rate, `115200`.
- Rebuild the slave bitstream.
- Run the master Vitis sender again.

Result:

- The received LED value followed the transmitted byte stream correctly.

## GPIO Bring-up

Before combining UART RX and LED display, GPIO behavior was checked separately with LED-only code.

Bring-up order:

1. Confirm GPIOC/GPIOD LED output works.
2. Confirm the master UART TX sends bytes.
3. Confirm the slave RX detects incoming UART frames.
4. Integrate RX byte display on GPIOC and receive-event toggle on GPIOD[0].
