#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

#define I2C_LCD_BASE    XPAR_I2C_LCD_AXI_0_S00_AXI_BASEADDR

#define I2C_LCD_CR      0x00
#define I2C_LCD_DATA    0x04
#define I2C_LCD_SR      0x08

#define CR_START        0x01
#define CR_CLR_STATUS   0x02

#define SR_BUSY         0x01
#define SR_DONE         0x02
#define SR_ACK_ERROR    0x04

static void print_sr(u32 sr)
{
    xil_printf("[LCD] SR   = 0x%08lx ", sr);

    xil_printf("[");
    if (sr & SR_BUSY) {
        xil_printf("BUSY ");
    }
    if (sr & SR_DONE) {
        xil_printf("DONE ");
    }
    if (sr & SR_ACK_ERROR) {
        xil_printf("ACK_ERROR ");
    }
    if ((sr & (SR_BUSY | SR_DONE | SR_ACK_ERROR)) == 0) {
        xil_printf("IDLE ");
    }
    xil_printf("]\r\n");
}

static int lcd_start_and_wait(void)
{
    u32 sr;
    int timeout;

    xil_printf("\r\n[LCD] clear status\r\n");

    /*
     * status clear
     */
    Xil_Out32(I2C_LCD_BASE + I2C_LCD_CR, CR_CLR_STATUS);
    usleep(1000);

    sr = Xil_In32(I2C_LCD_BASE + I2C_LCD_SR);
    print_sr(sr);

    /*
     * 현재 RTL에서는 DATA 레지스터를 아직 문자 출력에 사용하지 않음.
     * RTL 내부 i2c_lcd_core가 HELLO를 하드코딩해서 출력함.
     */
    Xil_Out32(I2C_LCD_BASE + I2C_LCD_DATA, 0x12345678);

    xil_printf("[LCD] start LCD init + HELLO output\r\n");

    /*
     * START trigger
     */
    Xil_Out32(I2C_LCD_BASE + I2C_LCD_CR, CR_START);

    /*
     * START pulse가 RTL에 들어가서 BUSY/DONE으로 반영될 시간 조금 대기
     */
    usleep(1000);

    /*
     * 핵심 수정:
     * BUSY가 0이면 바로 빠지는 방식이 아니라,
     * DONE 또는 ACK_ERROR가 뜰 때까지 기다림.
     */
    timeout = 20000000;

    while (timeout > 0) {
        sr = Xil_In32(I2C_LCD_BASE + I2C_LCD_SR);

        if (sr & SR_DONE) {
            break;
        }

        if (sr & SR_ACK_ERROR) {
            break;
        }

        timeout--;
    }

    xil_printf("[LCD] BASE = 0x%08lx\r\n", (u32)I2C_LCD_BASE);
    print_sr(sr);

    if (timeout <= 0) {
        xil_printf("[LCD] TIMEOUT: DONE/ACK_ERROR not received\r\n");
        return -1;
    }

    if (sr & SR_ACK_ERROR) {
        xil_printf("[LCD] FAIL: ACK ERROR\r\n");
        xil_printf("[LCD] Check LCD address, SDA/SCL, pull-up, power\r\n");
        return -2;
    }

    if (sr & SR_DONE) {
        xil_printf("[LCD] DONE: LCD init + HELLO sequence finished\r\n");
        xil_printf("[LCD] Check LCD screen now\r\n");
        return 0;
    }

    xil_printf("[LCD] FAIL: unknown status\r\n");
    return -3;
}

int main(void)
{
    xil_printf("\r\n============================\r\n");
    xil_printf("MicroBlaze I2C LCD HELLO Test\r\n");
    xil_printf("============================\r\n");

    xil_printf("I2C_LCD_BASE = 0x%08lx\r\n", (u32)I2C_LCD_BASE);

    /*
     * FPGA program 직후 LCD 전원 안정화 대기
     */
    xil_printf("[LCD] wait power stable...\r\n");
    sleep(1);

    /*
     * 딱 한 번만 실행
     */
    lcd_start_and_wait();

    xil_printf("[LCD] finished. Do not resend.\r\n");

    while (1) {
        sleep(1);
    }

    return 0;
}
