#include "device_driver.h"

#define LED_PIN_START 5U
#define LED_COUNT 3U
#define LED_MASK 0x7U

void LED_Init(void) {
  /* 아래 코드 수정 금지 : Port-A Clock Enable */
  Macro_Set_Bit(RCC->AHB1ENR, 0);

  // LED를 출력으로 설정하고 초기 OFF
  Macro_Write_Block(GPIOA->MODER, 0x3f, 0x15, LED_PIN_START * 2U);
  Macro_Clear_Area(GPIOA->OTYPER, LED_MASK, LED_PIN_START);
  Macro_Clear_Area(GPIOA->PUPDR, 0x3f, LED_PIN_START * 2U);
  Macro_Clear_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_On(void) {
  // LED On
  Macro_Set_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_Off(void) {
  // LED Off
  Macro_Clear_Area(GPIOA->ODR, LED_MASK, LED_PIN_START);
}

void LED_On_Number(unsigned int led) {
  if ((led >= 1U) && (led <= LED_COUNT)) {
    Macro_Set_Bit(GPIOA->ODR, LED_PIN_START + led - 1U);
  }
}

void LED_Off_Number(unsigned int led) {
  if ((led >= 1U) && (led <= LED_COUNT)) {
    Macro_Clear_Bit(GPIOA->ODR, LED_PIN_START + led - 1U);
  }
}

int LED_Get_State(unsigned int led) {
  if ((led < 1U) || (led > LED_COUNT)) {
    return 0;
  }

  return (int)Macro_Check_Bit_Set(GPIOA->ODR, LED_PIN_START + led - 1U);
}
