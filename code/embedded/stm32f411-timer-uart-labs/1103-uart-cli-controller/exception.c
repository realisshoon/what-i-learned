#include "device_driver.h"

extern volatile char Uart2_Rx_Buffer[];
extern volatile unsigned int Uart2_Rx_Index;
extern volatile unsigned int Uart2_Rx_Line_Complete;
extern volatile unsigned int Uart2_Rx_Overflow;
extern volatile unsigned int Uart2_Rx_Ignore_LF;
extern volatile unsigned int Timer_Tick_Count;

void USART2_IRQHandler(void) {
  unsigned int status = USART2->SR;

  if (status & (1U << 5)) {
    char data = (char)USART2->DR;

    if ((Uart2_Rx_Ignore_LF != 0U) && (data == '\n')) {
      Uart2_Rx_Ignore_LF = 0U;
    } else if (Uart2_Rx_Line_Complete != 0U) {
      /* Main이 이전 명령을 처리할 때까지 새 줄은 버림 */
    } else if (data == '\r') {
      Uart2_Rx_Line_Complete = 1U;
      Uart2_Rx_Ignore_LF = 1U;
    } else if (data == '\n') {
      Uart2_Rx_Line_Complete = 1U;
    } else if (Uart2_Rx_Overflow == 0U) {
      if (Uart2_Rx_Index + 1U < 64U) {
        Uart2_Rx_Buffer[Uart2_Rx_Index++] = data;
        Uart2_Rx_Buffer[Uart2_Rx_Index] = '\0';
      } else {
        Uart2_Rx_Index = 0U;
        Uart2_Rx_Overflow = 1U;
      }
    }
  } else if (status & 0x0fU) {
    (void)USART2->DR;
  }

  NVIC_ClearPendingIRQ(USART2_IRQn);
}

void TIM4_IRQHandler(void) {
  if (Macro_Check_Bit_Set(TIM4->SR, 0)) {
    Macro_Clear_Bit(TIM4->SR, 0);
    Timer_Tick_Count++;
  }

  NVIC_ClearPendingIRQ(TIM4_IRQn);
}
