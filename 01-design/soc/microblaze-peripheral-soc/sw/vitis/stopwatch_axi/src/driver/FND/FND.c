#include "FND.h"

static uint8_t fndDigits[4] = {0, 0, 0, 0};
static uint8_t fndDotMask = 0;

static const uint8_t fndFont[16] = {
    0xC0, // 0
    0xF9, // 1
    0xA4, // 2
    0xB0, // 3
    0x99, // 4
    0x92, // 5
    0x82, // 6
    0xF8, // 7
    0x80, // 8
    0x90, // 9
    0x88, // A
    0x83, // b
    0xC6, // C
    0xA1, // d
    0x86, // E
    0x8E  // F
};

void FND_init(void)
{
    uint32_t fndComTemp = GPIO_GetCR(FND_COM_GPIO);

    fndComTemp |= 0x0F;
    GPIO_SetMode(FND_COM_GPIO, fndComTemp);

    GPIO_SetMode(FND_DATA_GPIO, 0xFF);

    FND_SetDigits(0, 0, 0, 0, 0);
}

static void FND_DispAllOff(void)
{
    GPIO_WritePort(FND_COM_GPIO, GPIO_GetODR(FND_COM_GPIO) | 0x0F);
}

static void FND_SelDigit(uint32_t digit)
{
    uint32_t digitPos;

    digitPos = 0x0F;
    digitPos &= ~(1 << digit);

    GPIO_WritePort(FND_COM_GPIO, digitPos);
}

static void FND_DispDigit(uint8_t num, uint8_t dotOn)
{
    uint8_t data;

    data = fndFont[num & 0x0F];

    if (dotOn) {
        data &= ~0x80;    // DP ON, active-low
    }
    else {
        data |= 0x80;     // DP OFF
    }

    GPIO_WritePort(FND_DATA_GPIO, data);
}

void FND_SetDigits(uint8_t d3, uint8_t d2, uint8_t d1, uint8_t d0, uint8_t dotMask)
{
    fndDigits[3] = d3;
    fndDigits[2] = d2;
    fndDigits[1] = d1;
    fndDigits[0] = d0;

    fndDotMask = dotMask & 0x0F;
}

void FND_SetNum(uint32_t num)
{
    fndDigits[0] = num % 10;
    fndDigits[1] = (num / 10) % 10;
    fndDigits[2] = (num / 100) % 10;
    fndDigits[3] = (num / 1000) % 10;
}

void FND_SetDotMask(uint8_t dotMask)
{
    fndDotMask = dotMask & 0x0F;
}

void FND_Execute(void)
{
    static uint32_t fndDigitState = 0;
    uint8_t dotOn;

    fndDigitState = (fndDigitState + 1) % 4;

    FND_DispAllOff();

    dotOn = (fndDotMask >> fndDigitState) & 0x01;

    FND_SelDigit(fndDigitState);
    FND_DispDigit(fndDigits[fndDigitState], dotOn);
}
