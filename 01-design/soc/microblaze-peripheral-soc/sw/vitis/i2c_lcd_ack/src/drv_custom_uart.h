#ifndef DRV_CUSTOM_UART_H
#define DRV_CUSTOM_UART_H

#include "xil_types.h"

#define DRV_UART_SR_OFFSET  0x00U
#define DRV_UART_TDR_OFFSET 0x04U
#define DRV_UART_RDR_OFFSET 0x08U
#define DRV_UART_CR_OFFSET  0x0CU

#define DRV_UART_TX_READY   0x01U
#define DRV_UART_RX_VALID   0x02U
#define DRV_UART_RX_IE      0x01U

u32 drv_custom_uart_status(u32 base);
int drv_custom_uart_send_byte(u32 base, u8 value, u32 timeout);
int drv_custom_uart_read_byte(u32 base, u8 *value);
void drv_custom_uart_set_rx_irq(u32 base, int enable);

#endif
