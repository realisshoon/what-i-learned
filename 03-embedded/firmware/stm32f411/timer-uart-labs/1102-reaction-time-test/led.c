#include "device_driver.h"

#define LED_PIN_START 5U
#define LED_COUNT     3U
#define LED_MASK      0x7U

void LED_Init(void)
{
	/* 아래 코드 수정 금지 : Port-A Clock Enable */
	Macro_Set_Bit(RCC->AHB1ENR, 0); 

	// PA5, PA6, PA7을 출력으로 설정하고 초기 OFF
	Macro_Write_Block(GPIOA->MODER, 0x3f, 0x15, LED_PIN_START * 2U);
	Macro_Clear_Area(GPIOA->OTYPER, LED_MASK, LED_PIN_START);
	Macro_Clear_Area(GPIOA->PUPDR, 0x3f, LED_PIN_START * 2U);
	Macro_Clear_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_On(void)
{
	Macro_Set_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_Off(void)
{
	Macro_Clear_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_Select(unsigned int led)
{
	if((led < 1U) || (led > LED_COUNT))
	{
		return;
	}

	Macro_Write_Block(GPIOA->ODR, LED_MASK, 1U << (led - 1U), LED_PIN_START);
}
