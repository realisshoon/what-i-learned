#include "drv_custom_uart.h"
#include "hal_mmio.h"

u32 drv_custom_uart_status(u32 base)
{
    return hal_read32(base, DRV_UART_SR_OFFSET);
}

int drv_custom_uart_send_byte(u32 base, u8 value, u32 timeout)
{
    while (timeout > 0U) {
        if ((drv_custom_uart_status(base) & DRV_UART_TX_READY) != 0U) {
            hal_write32(base, DRV_UART_TDR_OFFSET, value);
            return 0;
        }

        timeout--;
    }

    return -1;
}

int drv_custom_uart_read_byte(u32 base, u8 *value)
{
    if ((drv_custom_uart_status(base) & DRV_UART_RX_VALID) == 0U) {
        return -1;
    }

    *value = (u8)(hal_read32(base, DRV_UART_RDR_OFFSET) & 0xFFU);
    return 0;
}

void drv_custom_uart_set_rx_irq(u32 base, int enable)
{
    hal_write32(base, DRV_UART_CR_OFFSET, enable ? DRV_UART_RX_IE : 0U);
}
