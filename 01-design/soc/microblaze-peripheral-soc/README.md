# MicroBlaze Multi-Peripheral SoC

Basys3에서 MicroBlaze와 AXI custom peripheral을 연결하고 Vitis C application으로 MMIO register를 제어한 학습 source를 정리합니다.

## 한눈에 보기

- MicroBlaze + AXI Interconnect block design
- custom GPIO, UART, Timer, I2C LCD peripheral
- AXI UARTLite와 interrupt controller
- Vitis C application
- MMIO HAL과 peripheral driver
- two-board UART experiment

## Hardware

보존된 `design_1.tcl`에는 MicroBlaze, LMB memory, AXI Interconnect, AXI UARTLite, interrupt controller가 있습니다. Custom IP로 GPIO 4개, UART, Timer, I2C LCD peripheral을 연결합니다.

I2C LCD IP는 AXI4-Lite register를 통해 START와 DATA를 받고 BUSY/DONE/ACK_ERROR 상태를 제공합니다. Bring-up 기록에는 PCF8574 기반 LCD address `0x27`, base address `0x44A60000`, `SR = 0x00000002 [DONE]`가 남아 있습니다.

## Software

Vitis source는 `Xil_In32`/`Xil_Out32` 또는 공통 MMIO helper로 custom register에 접근합니다.

- I2C LCD 초기화와 `HELLO` 출력 application
- GPIO, custom UART, I2C LCD용 driver/HAL
- SPI transfer driver source
- GPIO 기반 Stopwatch application

SPI driver source는 보존되어 있지만 현재 block design Tcl에는 SPI IP instance가 없습니다. Application에서도 platform의 SPI 존재 여부를 조건으로 처리합니다.

## Repository Structure

```text
microblaze-peripheral-soc/
├── hw/           # block design Tcl, constraints, custom IP RTL
├── sw/           # Vitis C applications, HAL, drivers
├── experiments/  # two-board UART/GPIO experiment
└── docs/         # register map과 bring-up 기록
```

Vivado/Vitis generated output과 BSP source는 저장하지 않았습니다. Software를 다시 build하려면 `xparameters.h`, `xil_io.h`, `xil_types.h` 등 target platform의 Xilinx BSP가 필요합니다.
