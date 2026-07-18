#include "device_driver.h"
#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define UART2_RX_BUFFER_SIZE 64U

volatile char Uart2_Rx_Buffer[UART2_RX_BUFFER_SIZE];
volatile unsigned int Uart2_Rx_Index;
volatile unsigned int Uart2_Rx_Line_Complete;
volatile unsigned int Uart2_Rx_Overflow;
volatile unsigned int Uart2_Rx_Ignore_LF;

void Uart2_Init(int baud) {
  double div;
  unsigned int mant;
  unsigned int frac;

  Macro_Set_Bit(RCC->AHB1ENR, 0);                  // PA2,3
  Macro_Set_Bit(RCC->APB1ENR, 17);                 // USART2 ON
  Macro_Write_Block(GPIOA->MODER, 0xf, 0xa, 4);    // PA2,3 => ALT
  Macro_Write_Block(GPIOA->AFR[0], 0xff, 0x77, 8); // PA2,3 => AF07
  Macro_Write_Block(GPIOA->PUPDR, 0xf, 0x5, 4);    // PA2,3 => Pull-Up

  volatile unsigned int t = GPIOA->LCKR & 0x7FFF;
  GPIOA->LCKR = (0x1 << 16) | t | (0x3 << 2); // Lock PA2, 3 Configuration
  GPIOA->LCKR = (0x0 << 16) | t | (0x3 << 2);
  GPIOA->LCKR = (0x1 << 16) | t | (0x3 << 2);
  t = GPIOA->LCKR;

  div = PCLK1 / (16. * baud);
  mant = (int)div;
  frac = (int)((div - mant) * 16. + 0.5);
  mant += frac >> 4;
  frac &= 0xf;

  USART2->BRR = (mant << 4) | (frac << 0);
  USART2->CR1 = (1 << 13) | (0 << 12) | (0 << 10) | (1 << 3) | (1 << 2);
  USART2->CR2 = 0 << 12;
  USART2->CR3 = 0;
}

void Uart2_Send_Byte(char data) {
  if (data == '\n') {
    while (!Macro_Check_Bit_Set(USART2->SR, 7))
      ;
    USART2->DR = 0x0d;
  }

  while (!Macro_Check_Bit_Set(USART2->SR, 7))
    ;
  USART2->DR = data;
}

void Uart2_Send_String(char *pt) {
  while (*pt != '\0') {
    Uart2_Send_Byte(*pt++);
  }
}

char Uart2_Get_Pressed(void) {
  if (Macro_Check_Bit_Set(USART2->SR, 5)) {
    return (char)USART2->DR;
  }

  return (char)0;
}

void Uart2_RX_Interrupt_Enable(int en) {
  if (en) {
    NVIC_ClearPendingIRQ(USART2_IRQn);
    NVIC_SetPriority(USART2_IRQn, 6U);
    Macro_Set_Bit(USART2->CR1, 5);
    NVIC_EnableIRQ(USART2_IRQn);
  } else {
    NVIC_DisableIRQ(USART2_IRQn);
    Macro_Clear_Bit(USART2->CR1, 5);
  }
}

int Uart2_Take_Line(char *line, unsigned int size) {
  unsigned int i;
  int result;

  if ((line == (char *)0) || (size == 0U)) {
    return 0;
  }

  __disable_irq();
  if (!Uart2_Rx_Line_Complete) {
    __enable_irq();
    return 0;
  }

  result = Uart2_Rx_Overflow ? -1 : 1;
  if (result > 0) {
    for (i = 0U; (i + 1U < size) && (Uart2_Rx_Buffer[i] != '\0'); i++) {
      line[i] = Uart2_Rx_Buffer[i];
    }
    line[i] = '\0';
  } else {
    line[0] = '\0';
  }

  Uart2_Rx_Index = 0U;
  Uart2_Rx_Line_Complete = 0U;
  Uart2_Rx_Overflow = 0U;
  __enable_irq();
  return result;
}

void Uart1_Init(int baud) {
  double div;
  unsigned int mant;
  unsigned int frac;

  Macro_Set_Bit(RCC->AHB1ENR, 0);                  // PA9,10
  Macro_Set_Bit(RCC->APB2ENR, 4);                  // USART1 ON
  Macro_Write_Block(GPIOA->MODER, 0xf, 0xa, 18);   // PA9,10 => ALT
  Macro_Write_Block(GPIOA->AFR[1], 0xff, 0x77, 4); // PA9,10 => AF07
  Macro_Write_Block(GPIOA->PUPDR, 0xf, 0x5, 18);   // PA9,10 => Pull-Up

  volatile unsigned int t = GPIOA->LCKR & 0x7FFF;
  GPIOA->LCKR = (0x1 << 16) | t | (0x3 << 9); // Lock PA9, 10 Configuration
  GPIOA->LCKR = (0x0 << 16) | t | (0x3 << 9);
  GPIOA->LCKR = (0x1 << 16) | t | (0x3 << 9);
  t = GPIOA->LCKR;

  div = PCLK2 / (16. * baud);
  mant = (int)div;
  frac = (int)((div - mant) * 16 + 0.5);
  mant += frac >> 4;
  frac &= 0xf;
  USART1->BRR = (mant << 4) | (frac << 0);

  USART1->CR1 = (1 << 13) | (0 << 12) | (0 << 10) | (1 << 3) | (1 << 2);
  USART1->CR2 = 0 << 12;
  USART1->CR3 = 0;
}

void Uart1_Send_Byte(char data) {
  if (data == '\n') {
    while (!Macro_Check_Bit_Set(USART1->SR, 7))
      ;
    USART1->DR = 0x0d;
  }

  while (!Macro_Check_Bit_Set(USART1->SR, 7))
    ;
  USART1->DR = data;
}

void Uart1_Send_String(char *pt) {
  while (*pt != 0) {
    Uart1_Send_Byte(*pt++);
  }
}

void Uart1_Printf(char *fmt, ...) {
  va_list ap;
  char string[256];

  va_start(ap, fmt);
  vsprintf(string, fmt, ap);
  Uart1_Send_String(string);
  va_end(ap);
}

char Uart1_Get_Pressed(void) {
  if (Macro_Check_Bit_Set(USART1->SR, 5)) {
    return (char)USART1->DR;
  }

  else {
    return (char)0;
  }
}

char Uart1_Get_Char(void) {
  while (!Macro_Check_Bit_Set(USART1->SR, 5))
    ;
  return (char)USART1->DR;
}
