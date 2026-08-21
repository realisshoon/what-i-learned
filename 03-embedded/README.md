# Embedded

STM32F411 기반 Bare-metal C 실습을 정리합니다. MicroBlaze firmware는 HW/SW 구성을 함께 볼 수 있도록 SoC 학습 단위에 보존했습니다.

## STM32F411

- [Timer / UART Labs](firmware/stm32f411/timer-uart-labs/) — TIM4 interrupt, GPIO LED, reaction-time FSM, USART2 CLI
- STM32 HAL 대신 CMSIS device header를 사용해 RCC, GPIO, TIM, USART, NVIC register를 직접 제어합니다.
- startup code, linker script, Makefile을 포함한 독립 firmware project 형태로 보존합니다.

## 관련 Firmware

- [MicroBlaze Peripheral SoC](../01-design/soc/microblaze-peripheral-soc/) — AXI MMIO 기반 GPIO, UART, Timer, I2C LCD driver/application
- BSP generated source는 포함하지 않으며 `xparameters.h`, `xil_io.h` 등 Vitis BSP dependency가 필요합니다.
