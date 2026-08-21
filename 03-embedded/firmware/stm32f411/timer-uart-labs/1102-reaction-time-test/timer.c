#include "device_driver.h"

#define TIM2_COUNTER_HZ 50000U
#define TIM2_TICK_US 20U
#define TIM4_POLL_HZ 50000U

static unsigned int TIM4_Limit_ARR(unsigned int arr) {
  if (arr > 0xffffU) {
    return 0xffffU;
  }

  return arr;
}

void TIM2_Stopwatch_Start(void) {
  Macro_Set_Bit(RCC->APB1ENR, 0);
  TIM2->CR1 = (1U << 4) | (1U << 3);
  TIM2->PSC = (TIMXCLK / TIM2_COUNTER_HZ) - 1U;
  TIM2->ARR = 0xffffU;
  TIM2->CNT = 0U;
  Macro_Set_Bit(TIM2->EGR, 0);
  TIM2->SR = 0U;
  Macro_Set_Bit(TIM2->CR1, 0);
}

unsigned int TIM2_Stopwatch_Stop(void) {
  unsigned int time;

  Macro_Clear_Bit(TIM2->CR1, 0);
  time = (0xffffU - TIM2->CNT) * TIM2_TICK_US;
  return time;
}

void TIM2_Delay(int time) {
  unsigned int ticks;

  if (time <= 0) {
    return;
  }

  Macro_Set_Bit(RCC->APB1ENR, 0);
  ticks = (unsigned int)time * (TIM2_COUNTER_HZ / 1000U);
  if (ticks == 0U) {
    ticks = 1U;
  }
  if (ticks > 0x10000U) {
    ticks = 0x10000U;
  }

  TIM2->CR1 = (1U << 4) | (1U << 3);
  TIM2->PSC = (TIMXCLK / TIM2_COUNTER_HZ) - 1U;
  TIM2->ARR = ticks - 1U;
  Macro_Set_Bit(TIM2->EGR, 0);
  TIM2->SR = 0U;
  Macro_Set_Bit(TIM2->CR1, 0);
  while (Macro_Check_Bit_Clear(TIM2->SR, 0)) {
  }
  Macro_Clear_Bit(TIM2->CR1, 0);
}

void TIM4_Repeat(int time) {
  unsigned int ticks;

  if (time <= 0) {
    return;
  }

  Macro_Set_Bit(RCC->APB1ENR, 2);
  ticks = (unsigned int)time * (TIM4_POLL_HZ / 1000U);
  if (ticks == 0U) {
    ticks = 1U;
  }
  if (ticks > 0x10000U) {
    ticks = 0x10000U;
  }

  TIM4->CR1 = 0U;
  TIM4->PSC = (TIMXCLK / TIM4_POLL_HZ) - 1U;
  TIM4->ARR = ticks - 1U;
  Macro_Set_Bit(TIM4->EGR, 0);
  TIM4->SR = 0U;
  Macro_Set_Bit(TIM4->CR1, 0);
}

int TIM4_Check_Timeout(void) {
  if (Macro_Check_Bit_Set(TIM4->SR, 0)) {
    Macro_Clear_Bit(TIM4->SR, 0);
    return 1;
  }

  return 0;
}

void TIM4_Stop(void) { Macro_Clear_Bit(TIM4->CR1, 0); }

void TIM4_Change_Value(int time) {
  if (time > 0) {
    TIM4->ARR =
        TIM4_Limit_ARR((unsigned int)time * (TIM4_POLL_HZ / 1000U) - 1U);
  }
}

void TIM4_Repeat_Interrupt_Enable(int en, unsigned int arr) {
  if (en) {
    Macro_Set_Bit(RCC->APB1ENR, 2);
    NVIC_DisableIRQ(TIM4_IRQn);
    TIM4->CR1 = 0U;
    TIM4->DIER = 0U;
    TIM4->PSC = (TIMXCLK / TIM4_COUNTER_HZ) - 1U;
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
  } else {
    NVIC_DisableIRQ(TIM4_IRQn);
    Macro_Clear_Bit(TIM4->CR1, 0);
    Macro_Clear_Bit(TIM4->DIER, 0);
    TIM4->SR = 0U;
    NVIC_ClearPendingIRQ(TIM4_IRQn);
  }
}
