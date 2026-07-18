#include "device_driver.h"
#include <stdio.h>

#define CLI_LINE_SIZE 64U
#define CLI_MAX_TOKENS 4U
#define TIMER_MIN_SECONDS 1U
#define TIMER_MAX_SECONDS 60U
#define TIMER_BLINK_TICKS (500U / CLI_TICK_MS)
#define TIMER_MAX_BLINKS 3U

typedef enum {
  TIMER_IDLE,
  TIMER_WAIT,
  TIMER_BLINK_ON,
  TIMER_BLINK_OFF
} TIMER_STATE;

volatile unsigned int Timer_Tick_Count;
static TIMER_STATE Timer_State;
static unsigned int Timer_State_Tick;
static unsigned int Timer_Blink_Count;

static void Sys_Init(int baud) {
  SCB->CPACR |= (0x3 << 10 * 2) | (0x3 << 11 * 2);
  Clock_Init();
  Uart2_Init(baud);
  setvbuf(stdout, NULL, _IONBF, 0);
  LED_Init();
  Key_Poll_Init();
}

static int String_Equals(const char *left, const char *right) {
  while ((*left != '\0') && (*left == *right)) {
    left++;
    right++;
  }
  return (*left == *right);
}

static int Parse_Unsigned(const char *text, unsigned int *value) {
  unsigned int result = 0U;

  if (*text == '\0')
    return 0;

  while (*text != '\0') {
    if ((*text < '0') || (*text > '9') || (result > 100000U))
      return 0;
    result = result * 10U + (unsigned int)(*text - '0');
    text++;
  }

  *value = result;
  return 1;
}

static unsigned int Tokenize(char *line, char *argv[],
                             unsigned int max_tokens) {
  unsigned int count = 0U;
  char *cursor = line;

  while ((*cursor != '\0') && (count < max_tokens)) {
    while ((*cursor == ' ') || (*cursor == '\t'))
      cursor++;
    if (*cursor == '\0')
      break;

    argv[count++] = cursor;
    while ((*cursor != '\0') && (*cursor != ' ') && (*cursor != '\t'))
      cursor++;
    if (*cursor != '\0')
      *cursor++ = '\0';
  }

  return count;
}

static unsigned int Tick_Elapsed(unsigned int now, unsigned int start) {
  return now - start;
}

static void Print_Help(void) {
  Uart2_Send_String(
      "help\nled on [1-3]\nled off [1-3]\nstatus\ntimer [1-60]\n");
}

static void Print_Status(void) {
  printf("LED1=%s LED2=%s LED3=%s Key1=%s Key2=%s\n",
         LED_Get_State(1U) ? "ON" : "OFF", LED_Get_State(2U) ? "ON" : "OFF",
         LED_Get_State(3U) ? "ON" : "OFF",
         Key_Get_Pressed() ? "PRESSED" : "RELEASED",
         Key2_Get_Pressed() ? "PRESSED" : "RELEASED");
}

static void Timer_Start(unsigned int seconds) {
  if ((Timer_State != TIMER_IDLE) || (seconds < TIMER_MIN_SECONDS) ||
      (seconds > TIMER_MAX_SECONDS)) {
    Uart2_Send_String("Invalid timer value or timer is busy.\n");
    return;
  }

  LED_Off();
  Timer_State = TIMER_WAIT;
  Timer_State_Tick = Timer_Tick_Count + (seconds * 1000U / CLI_TICK_MS);
  Timer_Blink_Count = 0U;
  printf("Timer started: %u second(s)\n", seconds);
}

static void Timer_Process(unsigned int now) {
  switch (Timer_State) {
  case TIMER_WAIT:
    if ((int)(now - Timer_State_Tick) >= 0) {
      LED_On();
      Timer_State = TIMER_BLINK_ON;
      Timer_State_Tick = now;
    }
    break;

  case TIMER_BLINK_ON:
    if (Tick_Elapsed(now, Timer_State_Tick) >= TIMER_BLINK_TICKS) {
      LED_Off();
      Timer_State = TIMER_BLINK_OFF;
      Timer_State_Tick = now;
    }
    break;

  case TIMER_BLINK_OFF:
    if (Tick_Elapsed(now, Timer_State_Tick) >= TIMER_BLINK_TICKS) {
      Timer_Blink_Count++;
      if (Timer_Blink_Count >= TIMER_MAX_BLINKS) {
        Timer_State = TIMER_IDLE;
        Uart2_Send_String("Timer done.\n");
      } else {
        LED_On();
        Timer_State = TIMER_BLINK_ON;
      }
      Timer_State_Tick = now;
    }
    break;

  case TIMER_IDLE:
  default:
    break;
  }
}

static void Execute_Command(char *line) {
  char *argv[CLI_MAX_TOKENS];
  unsigned int argc = Tokenize(line, argv, CLI_MAX_TOKENS);
  unsigned int value;

  if (argc == 0U)
    return;

  if ((argc == 1U) && String_Equals(argv[0], "help")) {
    Print_Help();
  } else if ((argc == 1U) && String_Equals(argv[0], "status")) {
    Print_Status();
  } else if ((argc == 3U) && String_Equals(argv[0], "led") &&
             (String_Equals(argv[1], "on") || String_Equals(argv[1], "off"))) {
    if (!Parse_Unsigned(argv[2], &value) || (value < 1U) || (value > 3U))
      Uart2_Send_String("Invalid LED number. Use 1-3.\n");
    else if (String_Equals(argv[1], "on"))
      LED_On_Number(value);
    else
      LED_Off_Number(value);
  } else if ((argc == 2U) && String_Equals(argv[0], "timer")) {
    if (Parse_Unsigned(argv[1], &value))
      Timer_Start(value);
    else
      Uart2_Send_String("Invalid timer value. Use 1-60 seconds.\n");
  } else {
    Uart2_Send_String("Unknown command. Type 'help'.\n");
  }
}

void Main(void) {
  char line[CLI_LINE_SIZE];
  int line_status;

  Sys_Init(115200);
  Timer_Tick_Count = 0U;
  Timer_State = TIMER_IDLE;
  TIM4_Repeat_Interrupt_Enable(1, CLI_TIMER_ARR);
  Uart2_RX_Interrupt_Enable(1);
  Uart2_Send_String("UART CLI ready. Type 'help'.\n> ");

  for (;;) {
    Timer_Process(Timer_Tick_Count);
    line_status = Uart2_Take_Line(line, sizeof(line));
    if (line_status < 0) {
      Uart2_Send_String("Command too long.\n> ");
    } else if (line_status > 0) {
      Execute_Command(line);
      Uart2_Send_String("> ");
    }
  }
}
