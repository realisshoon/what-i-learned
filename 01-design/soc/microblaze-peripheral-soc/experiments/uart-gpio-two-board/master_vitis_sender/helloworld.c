#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include <stdint.h>

#define UART_BASEADDR  XPAR_UART_0_S00_AXI_BASEADDR
#define GPIOC_BASEADDR XPAR_GPIO_2_S00_AXI_BASEADDR
#define GPIOD_BASEADDR XPAR_GPIO_3_S00_AXI_BASEADDR

#define UART_SR_OFFSET  0x00U
#define UART_TDR_OFFSET 0x04U
#define UART_TX_READY   0x00000001U

#define GPIO_CR_OFFSET  0x00U
#define GPIO_ODR_OFFSET 0x08U
#define GPIO_OUTPUT_EN  0x000000FFU
#define GPIO_LED_MASK   0x000000FFU

static void gpio_init_leds(void)
{
    Xil_Out32(GPIOC_BASEADDR + GPIO_CR_OFFSET, GPIO_OUTPUT_EN);
    Xil_Out32(GPIOD_BASEADDR + GPIO_CR_OFFSET, GPIO_OUTPUT_EN);
}

static void gpio_show_leds(uint16_t value)
{
    Xil_Out32(GPIOC_BASEADDR + GPIO_ODR_OFFSET,
              (uint32_t)(value & GPIO_LED_MASK));
    Xil_Out32(GPIOD_BASEADDR + GPIO_ODR_OFFSET,
              (uint32_t)((value >> 8) & GPIO_LED_MASK));
}

static void uart_send_byte(uint8_t value)
{
    while ((Xil_In32(UART_BASEADDR + UART_SR_OFFSET) & UART_TX_READY) == 0U) {
    }

    Xil_Out32(UART_BASEADDR + UART_TDR_OFFSET, (uint32_t)value);
}

int main(void)
{
    uint8_t tx_value = (uint8_t)0x55U;

    gpio_init_leds();

    for (;;) {
        uart_send_byte(tx_value);
        gpio_show_leds((uint16_t)tx_value);

        tx_value = (uint8_t)(tx_value + 1U);
        usleep(500000);
    }
}
