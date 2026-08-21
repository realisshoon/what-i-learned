#include "board_io.h"
#include "drv_custom_uart.h"
#include "drv_lcd.h"
#include "drv_spi.h"
#include "hal_addresses.h"
#include "xil_printf.h"
#include "xil_types.h"

#define APP_UART_TIMEOUT 1000000U
#define APP_LCD_TIMEOUT  20000000U
#define APP_SPI_TIMEOUT  1000000U
#define APP_SPI_CLK_DIV  100U

static u8 button_rising_edge(u8 current, u8 previous, u8 mask)
{
    return (u8)(((current & mask) != 0U) && ((previous & mask) == 0U));
}

static void show_ready_screen(void)
{
    int lcd_ret = drv_lcd_show(APP_I2C_LCD_BASE, DRV_LCD_MODE_SW, 0x00U,
                               APP_LCD_TIMEOUT);
    xil_printf("[READY] LCD ret=%d\r\n", lcd_ret);
}

static void handle_uart_event(u8 value)
{
    int uart_ret;
    int lcd_ret;

    board_led_write(value);

    uart_ret = drv_custom_uart_send_byte(APP_CUSTOM_UART_BASE, value,
                                         APP_UART_TIMEOUT);
    if (uart_ret != 0) {
        xil_printf("[CUSTOM UART] TX timeout SR=0x%08lx\r\n",
                   (unsigned long)drv_custom_uart_status(APP_CUSTOM_UART_BASE));
    }

    lcd_ret = drv_lcd_show(APP_I2C_LCD_BASE, DRV_LCD_MODE_UART, value,
                           APP_LCD_TIMEOUT);

    xil_printf("[UART] DATA=0x%02x UART ret=%d LCD ret=%d\r\n",
               value, uart_ret, lcd_ret);
}

static void handle_spi_event(u8 value)
{
#if APP_HAS_SPI
    u8 spi_rx;
    int spi_ret;
    int lcd_ret;

    board_led_write(value);

    spi_ret = drv_spi_transfer_byte(APP_SPI_BASE, value, APP_SPI_CLK_DIV,
                                    APP_SPI_TIMEOUT, &spi_rx);
    lcd_ret = drv_lcd_show(APP_I2C_LCD_BASE, DRV_LCD_MODE_SPI, value,
                           APP_LCD_TIMEOUT);

    xil_printf("[SPI] TX=0x%02x RX=0x%02x SPI ret=%d LCD ret=%d\r\n",
               value, spi_rx, spi_ret, lcd_ret);
#else
    xil_printf("[SPI] SPI_0 is not present in this platform\r\n");
#endif
}

static void handle_timer_event(u8 value)
{
    int lcd_ret;

    board_led_write(value);

    lcd_ret = drv_lcd_show(APP_I2C_LCD_BASE, DRV_LCD_MODE_TIMER, value,
                           APP_LCD_TIMEOUT);

    xil_printf("[TIMER] CNT=0x%02x LCD ret=%d\r\n", value, lcd_ret);
}

static void handle_clear_event(void)
{
    int lcd_ret;

    board_led_write(0x00U);
    board_fnd_off();

    lcd_ret = drv_lcd_show(APP_I2C_LCD_BASE, DRV_LCD_MODE_SW, 0x00U,
                           APP_LCD_TIMEOUT);

    xil_printf("[CLEAR] LCD ret=%d\r\n", lcd_ret);
}

int main(void)
{
    u8 previous_buttons;
    u8 display_value;
    u8 timer_value;
    u8 switches;
    u8 buttons;

    previous_buttons = 0x00U;
    display_value = 0x00U;
    timer_value = 0x00U;

    xil_printf("\r\n============================\r\n");
    xil_printf("MASTER BUTTON MODE TEST\r\n");
    xil_printf("============================\r\n");

    board_io_init();
    show_ready_screen();

    while (1) {
        switches = board_read_switches();
        buttons = board_read_buttons();

        if (button_rising_edge(buttons, previous_buttons, BOARD_BTN_UART)) {
            display_value = switches;
            handle_uart_event(display_value);
            board_wait_button_release();
        }

        if (button_rising_edge(buttons, previous_buttons, BOARD_BTN_SPI)) {
            display_value = switches;
            handle_spi_event(display_value);
            board_wait_button_release();
        }

        if (button_rising_edge(buttons, previous_buttons, BOARD_BTN_TIMER)) {
            timer_value++;
            display_value = timer_value;
            handle_timer_event(display_value);
            board_wait_button_release();
        }

        if (button_rising_edge(buttons, previous_buttons, BOARD_BTN_CLEAR)) {
            display_value = 0x00U;
            timer_value = 0x00U;
            handle_clear_event();
            board_wait_button_release();
        }

        board_fnd_display_hex_once(display_value);
        previous_buttons = buttons;
    }

    return 0;
}
