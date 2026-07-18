#include "device_driver.h"

static unsigned int TIM4_Limit_ARR(unsigned int arr)
{
	if(arr < LED_TIMER_ARR_MIN)
		return LED_TIMER_ARR_MIN;
	if(arr > LED_TIMER_ARR_MAX)
		return LED_TIMER_ARR_MAX;
	return arr;
}

void TIM4_Repeat_Interrupt_Enable(int en, unsigned int arr)
{
	if(en)
	{
		Macro_Set_Bit(RCC->APB1ENR, 2);
		NVIC_DisableIRQ(TIM4_IRQn);
		TIM4->CR1 = 0U;
		TIM4->DIER = 0U;
		TIM4->PSC = (TIMXCLK / LED_TIMER_COUNTER_HZ) - 1U;
		TIM4->ARR = TIM4_Limit_ARR(arr);
		TIM4->CNT = 0U;
		Macro_Set_Bit(TIM4->CR1, 7);
		Macro_Set_Bit(TIM4->EGR, 0);
		TIM4->SR = 0U;
		NVIC_ClearPendingIRQ(TIM4_IRQn);
		NVIC_SetPriority(TIM4_IRQn, 5U);
		Macro_Set_Bit(TIM4->DIER, 0);
		NVIC_EnableIRQ(TIM4_IRQn);
		Macro_Set_Bit(TIM4->CR1, 0);
	}
	else
	{
		NVIC_DisableIRQ(TIM4_IRQn);
		Macro_Clear_Bit(TIM4->CR1, 0);
		Macro_Clear_Bit(TIM4->DIER, 0);
		TIM4->SR = 0U;
		NVIC_ClearPendingIRQ(TIM4_IRQn);
	}
}

void TIM4_Change_Value(unsigned int arr)
{
	TIM4->ARR = TIM4_Limit_ARR(arr);
}
