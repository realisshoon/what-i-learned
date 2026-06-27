# Register Map

## I2C LCD AXI IP

Base address:

```c
#define I2C_LCD_BASE 0x44A60000
```

Vitis macro observed in `xparameters.h`:

```c
#define XPAR_I2C_LCD_AXI_0_S00_AXI_BASEADDR 0x44A60000
```

| Offset | Register | Access | Description |
| --- | --- | --- | --- |
| `0x00` | `CR` | write | Control register |
| `0x04` | `DATA` | read/write | Data register |
| `0x08` | `SR` | read | Status register |
| `0x0C` | reserved | reserved | Not used |

## CR: Control Register

| Bit | Name | Description |
| --- | --- | --- |
| `0` | `START` | Starts the LCD initialization and `HELLO` output sequence |
| `1` | `CLR_STATUS` | Clears latched `DONE` and `ACK_ERROR` status |

## DATA: Data Register

| Bits | Description |
| --- | --- |
| `[31:0]` | Software-visible data register. The current RTL success path prints a fixed `HELLO` sequence. |

## SR: Status Register

| Bit | Name | Description |
| --- | --- | --- |
| `0` | `BUSY` | LCD sequence is running |
| `1` | `DONE` | LCD sequence completed successfully |
| `2` | `ACK_ERROR` | I2C address or data ACK failed |

Successful status:

```text
SR = 0x00000002 [DONE]
```

## GPIO Address Notes

The current exported platform exposes these GPIO macros:

```c
#define XPAR_GPIO_0_S00_AXI_BASEADDR 0x44A00000
#define XPAR_GPIO_1_S00_AXI_BASEADDR 0x44A10000
#define XPAR_GPIO_2_S00_AXI_BASEADDR 0x44A20000
#define XPAR_GPIO_3_S00_AXI_BASEADDR 0x44A30000
```

Current LED usage:

- `GPIOC` is connected to Basys3 LED lower bank pins.
- `GPIOD` is connected to Basys3 LED upper bank pins.

Next GPIO input work should confirm or add switch and button constraints before writing the Vitis read test.
