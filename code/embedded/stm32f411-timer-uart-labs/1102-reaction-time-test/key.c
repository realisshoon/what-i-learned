#include "device_driver.h"

#define KEY1_PIN 13U
#define KEY2_PIN 7U

void Key_Poll_Init(void)
{
	Macro_Set_Bit(RCC->AHB1ENR, 2); 
	Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, KEY1_PIN * 2U);
	Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, KEY2_PIN * 2U);
	Macro_Write_Block(GPIOC->PUPDR, 0x3, 0x1, KEY2_PIN * 2U);
}

int Key_Get_Pressed(void)
{
	return Macro_Check_Bit_Clear(GPIOC->IDR, KEY1_PIN);
}

int Key2_Get_Pressed(void)
{
	return Macro_Check_Bit_Clear(GPIOC->IDR, KEY2_PIN);
}

void Key_Wait_Key_Pressed(void)
{
	while(!Macro_Check_Bit_Clear(GPIOC->IDR, KEY1_PIN));
}

void Key_Wait_Key_Released(void)
{
	while(!Macro_Check_Bit_Set(GPIOC->IDR, KEY1_PIN));
}
