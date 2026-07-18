#include "device_driver.h"

void SysTick_Run(unsigned int msec) {
  // Timer 설정 : 인터럽트 발생 안함, clock source는 HCLK/8, Timer 정지
  SysTick->CTRL = 0U;

  // 주어진 msec 값 만큼의 msec를 count하는 초기값 설정 (LOAD)
  const unsigned int ticks_per_msec = HCLK / (8U * 1000U);
  const unsigned int max_ticks = SysTick_LOAD_RELOAD_Msk + 1U;
  unsigned int ticks;

  if (msec == 0U) {
    ticks = 1U;
  } else if (msec > (max_ticks / ticks_per_msec)) {
    ticks = max_ticks;
  } else {
    ticks = ticks_per_msec * msec;
  }

  SysTick->LOAD = ticks - 1U;

  // VAL 레지스터 값 초기화(0) 및 COUNTFLAG Clear
  SysTick->VAL = 0U;

  // Timer Start (시작이 되면 자동으로 LOAD의 값을 VAL로 가져간다)
  SysTick->CTRL = SysTick_CTRL_ENABLE_Msk;
}

int SysTick_Check_Timeout(void) {
  // Timer의 Timeout이 발생하면 참(1)리턴, 아니면 거짓(0) 리턴
  return (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) != 0U;
}

unsigned int SysTick_Get_Time(void) {
  // Timer의 현재 count 값 리턴
  return SysTick->VAL;
}

unsigned int SysTick_Get_Load_Time(void) {
  // Timer에 설정된 초기값을 리턴
  return SysTick->LOAD;
}

void SysTick_Stop(void) {
  // Timer Stop
  SysTick->CTRL = 0U;
}
