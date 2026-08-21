#include "device_driver.h"

extern volatile unsigned int Timer_Tick_Count;

void TIM4_IRQHandler(void)
{
	if(Macro_Check_Bit_Set(TIM4->SR, 0))
	{
		Macro_Clear_Bit(TIM4->SR, 0);
		Timer_Tick_Count++;
	}

	NVIC_ClearPendingIRQ(TIM4_IRQn);
}
