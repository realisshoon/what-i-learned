#include "device_driver.h"
#include <stdio.h>

#define LED_LEFT  1U
#define LED_RIGHT 3U

volatile unsigned int Timer_Event_Flag;
static unsigned int LED_Position;
static int LED_Direction;
static int LED_Stopped;
static int Ping_Print_Flag;
static int Pong_Print_Flag;
static unsigned int Timer_ARR;

static void Sys_Init(int baud)
{
	SCB->CPACR |= (0x3 << 10*2)|(0x3 << 11*2);
	Clock_Init();
	Uart2_Init(baud);
	setvbuf(stdout, NULL, _IONBF, 0);
	LED_Init();
}

static int Timer_Event_Take(void)
{
	int event;
	__disable_irq();
	event = (Timer_Event_Flag != 0U);
	Timer_Event_Flag = 0U;
	__enable_irq();
	return event;
}

static void Timer_Event_Clear(void)
{
	__disable_irq();
	Timer_Event_Flag = 0U;
	__enable_irq();
}

static void LED_State_Update(void)
{
	if(LED_Direction > 0)
	{
		LED_Position++;
		if(LED_Position == LED_RIGHT)
		{
			LED_Direction = -1;
			Pong_Print_Flag = 1;
		}
	}
	else
	{
		LED_Position--;
		if(LED_Position == LED_LEFT)
		{
			LED_Direction = 1;
			Ping_Print_Flag = 1;
		}
	}
	LED_Select(LED_Position);
}

static void UART_Command_Process(char command)
{
	if(command == 'u')
	{
		if(Timer_ARR > (LED_TIMER_ARR_MIN + LED_TIMER_ARR_STEP))
			Timer_ARR -= LED_TIMER_ARR_STEP;
		else
			Timer_ARR = LED_TIMER_ARR_MIN;
		TIM4_Change_Value(Timer_ARR);
		printf("[SPEED UP] ARR=%u\n", Timer_ARR);
	}
	else if(command == 'd')
	{
		if(Timer_ARR < (LED_TIMER_ARR_MAX - LED_TIMER_ARR_STEP))
			Timer_ARR += LED_TIMER_ARR_STEP;
		else
			Timer_ARR = LED_TIMER_ARR_MAX;
		TIM4_Change_Value(Timer_ARR);
		printf("[SPEED DOWN] ARR=%u\n", Timer_ARR);
	}
	else if(command == 's')
	{
		LED_Stopped ^= 1;
		if(LED_Stopped)
		{
			TIM4_Repeat_Interrupt_Enable(0, Timer_ARR);
			Timer_Event_Clear();
			printf("[STOP]\n");
		}
		else
		{
			TIM4_Repeat_Interrupt_Enable(1, Timer_ARR);
			printf("[START]\n");
		}
	}
}

static void Debug_Message_Process(void)
{
	if(Ping_Print_Flag)
	{
		Ping_Print_Flag = 0;
		Uart2_Send_String("[PING]\n");
	}
	if(Pong_Print_Flag)
	{
		Pong_Print_Flag = 0;
		Uart2_Send_String("[PONG]\n");
	}
}

void Main(void)
{
	char command;

	Sys_Init(115200);
	Timer_Event_Flag = 0U;
	LED_Position = LED_LEFT;
	LED_Direction = 1;
	LED_Stopped = 0;
	Ping_Print_Flag = 1;
	Pong_Print_Flag = 0;
	Timer_ARR = LED_TIMER_ARR_INIT;
	LED_Select(LED_Position);
	printf("LED Ping-Pong: u=up, d=down, s=stop/start\n");
	Debug_Message_Process();
	TIM4_Repeat_Interrupt_Enable(1, Timer_ARR);

	for(;;)
	{
		command = Uart2_Get_Pressed();
		if(command != (char)0)
			UART_Command_Process(command);
		if(Timer_Event_Take() && !LED_Stopped)
			LED_State_Update();
		Debug_Message_Process();
	}
}
