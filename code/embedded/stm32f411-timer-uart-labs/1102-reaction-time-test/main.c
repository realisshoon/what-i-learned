#include "device_driver.h"
#include <stdio.h>

#define RANDOM_WAIT_MIN_MS 1000U
#define RANDOM_WAIT_MAX_MS 4000U
#define IDLE_BLINK_PERIOD_MS 500U
#define RESULT_HOLD_MS 2000U
#define KEY_DEBOUNCE_SAMPLES 4U

#define RANDOM_WAIT_MIN_TICKS (RANDOM_WAIT_MIN_MS / GAME_TICK_MS)
#define RANDOM_WAIT_MAX_TICKS (RANDOM_WAIT_MAX_MS / GAME_TICK_MS)
#define IDLE_BLINK_TICKS (IDLE_BLINK_PERIOD_MS / GAME_TICK_MS)
#define RESULT_HOLD_TICKS (RESULT_HOLD_MS / GAME_TICK_MS)

typedef enum {
  GAME_IDLE,
  GAME_RANDOM_WAIT,
  GAME_REACTION,
  GAME_RESULT,
  GAME_FOUL
} GAME_STATE;

typedef struct {
  unsigned int stable_pressed;
  unsigned int candidate_pressed;
  unsigned int sample_count;
  unsigned int press_event;
  unsigned int candidate_tick;
  unsigned int press_tick;
} KEY_FILTER;

volatile unsigned int Timer_Tick_Count;

static GAME_STATE Game_State;
static KEY_FILTER Key1_Filter;
static KEY_FILTER Key2_Filter;
static unsigned int State_Start_Tick;
static unsigned int Last_Blink_Tick;
static unsigned int Last_Key_Scan_Tick;
static unsigned int Random_Wait_Ticks;
static unsigned int Reaction_Start_Tick;
static unsigned int LED_Blink_On;
static unsigned short Random_LFSR = 0xace1U;

static void Sys_Init(int baud) {
  SCB->CPACR |= (0x3 << 10 * 2) | (0x3 << 11 * 2);
  Clock_Init();
  Uart2_Init(baud);
  setvbuf(stdout, NULL, _IONBF, 0);
  LED_Init();
  Key_Poll_Init();
}

static unsigned int Tick_Elapsed(unsigned int now, unsigned int start) {
  return now - start;
}

static void Key_Filter_Init(KEY_FILTER *filter, unsigned int pressed,
                            unsigned int now) {
  filter->stable_pressed = pressed;
  filter->candidate_pressed = pressed;
  filter->sample_count = KEY_DEBOUNCE_SAMPLES;
  filter->press_event = 0U;
  filter->candidate_tick = now;
  filter->press_tick = now;
}

static void Key_Filter_Update(KEY_FILTER *filter, unsigned int pressed,
                              unsigned int now) {
  if (pressed != filter->candidate_pressed) {
    filter->candidate_pressed = pressed;
    filter->sample_count = 1U;
    filter->candidate_tick = now;
  } else if (filter->sample_count < KEY_DEBOUNCE_SAMPLES) {
    filter->sample_count++;
  }

  if ((filter->sample_count >= KEY_DEBOUNCE_SAMPLES) &&
      (filter->stable_pressed != filter->candidate_pressed)) {
    filter->stable_pressed = filter->candidate_pressed;

    if (filter->stable_pressed) {
      filter->press_tick = filter->candidate_tick;
      filter->press_event = 1U;
    }
  }
}

static int Key_Filter_Take_Press(KEY_FILTER *filter, unsigned int *press_tick) {
  int pressed = (filter->press_event != 0U);

  if (pressed && (press_tick != NULL)) {
    *press_tick = filter->press_tick;
  }

  filter->press_event = 0U;
  return pressed;
}

static void Key_Scan_Process(unsigned int now) {
  if (now == Last_Key_Scan_Tick) {
    return;
  }

  Last_Key_Scan_Tick = now;
  Key_Filter_Update(&Key1_Filter, (unsigned int)Key_Get_Pressed(), now);
  Key_Filter_Update(&Key2_Filter, (unsigned int)Key2_Get_Pressed(), now);
}

static unsigned int Random_Wait_Create(unsigned int now) {
  unsigned int feedback;
  unsigned int range;

  Random_LFSR ^= (unsigned short)(now ^ TIM4->CNT);
  if (Random_LFSR == 0U) {
    Random_LFSR = 0xace1U;
  }

  feedback = Random_LFSR & 0x1U;
  Random_LFSR >>= 1;
  if (feedback) {
    Random_LFSR ^= 0xb400U;
  }

  range = RANDOM_WAIT_MAX_TICKS - RANDOM_WAIT_MIN_TICKS + 1U;
  return RANDOM_WAIT_MIN_TICKS + ((unsigned int)Random_LFSR % range);
}

static void Game_Enter_Idle(unsigned int now) {
  Game_State = GAME_IDLE;
  State_Start_Tick = now;
  Last_Blink_Tick = now;
  LED_Blink_On = 1U;
  LED_On();
  Uart2_Send_String("Press Key 1 to Start!\n");
}

static void Game_Enter_Foul(unsigned int now) {
  Game_State = GAME_FOUL;
  State_Start_Tick = now;
  LED_Off();
  Uart2_Send_String("Foul Play!\n");
}

static void Game_Idle_Process(unsigned int now) {
  unsigned int key_tick;

  (void)Key_Filter_Take_Press(&Key2_Filter, NULL);

  if (Tick_Elapsed(now, Last_Blink_Tick) >= IDLE_BLINK_TICKS) {
    Last_Blink_Tick = now;
    LED_Blink_On ^= 1U;
    LED_Blink_On ? LED_On() : LED_Off();
  }

  if (Key_Filter_Take_Press(&Key1_Filter, &key_tick)) {
    LED_Off();
    Random_Wait_Ticks = Random_Wait_Create(key_tick);
    State_Start_Tick = now;
    Game_State = GAME_RANDOM_WAIT;
  }
}

static void Game_Random_Wait_Process(unsigned int now) {
  (void)Key_Filter_Take_Press(&Key1_Filter, NULL);

  if (Key2_Filter.stable_pressed || Key_Filter_Take_Press(&Key2_Filter, NULL)) {
    Game_Enter_Foul(now);
  } else if (Tick_Elapsed(now, State_Start_Tick) >= Random_Wait_Ticks) {
    LED_On();
    Uart2_Send_String("PRESS KEY NOW!\n");
    Reaction_Start_Tick = now;
    Game_State = GAME_REACTION;
  }
}

static void Game_Reaction_Process(unsigned int now) {
  unsigned int key_tick;
  unsigned int reaction_ms;

  (void)Key_Filter_Take_Press(&Key1_Filter, NULL);

  if (Key_Filter_Take_Press(&Key2_Filter, &key_tick)) {
    reaction_ms = Tick_Elapsed(key_tick, Reaction_Start_Tick) * GAME_TICK_MS;
    printf("Your reaction time: %u ms!\n", reaction_ms);
    State_Start_Tick = now;
    Game_State = GAME_RESULT;
  }
}

static void Game_Result_Process(unsigned int now) {
  (void)Key_Filter_Take_Press(&Key1_Filter, NULL);
  (void)Key_Filter_Take_Press(&Key2_Filter, NULL);

  if (Tick_Elapsed(now, State_Start_Tick) >= RESULT_HOLD_TICKS) {
    Game_Enter_Idle(now);
  }
}

static void Game_Process(unsigned int now) {
  switch (Game_State) {
  case GAME_IDLE:
    Game_Idle_Process(now);
    break;

  case GAME_RANDOM_WAIT:
    Game_Random_Wait_Process(now);
    break;

  case GAME_REACTION:
    Game_Reaction_Process(now);
    break;

  case GAME_RESULT:
  case GAME_FOUL:
    Game_Result_Process(now);
    break;

  default:
    Game_Enter_Idle(now);
    break;
  }
}

void Main(void) {
  unsigned int now;
  char command;

  Sys_Init(115200);
  Timer_Tick_Count = 0U;
  Key_Filter_Init(&Key1_Filter, (unsigned int)Key_Get_Pressed(), 0U);
  Key_Filter_Init(&Key2_Filter, (unsigned int)Key2_Get_Pressed(), 0U);
  Last_Key_Scan_Tick = 0U;

  TIM4_Repeat_Interrupt_Enable(1, GAME_TIMER_ARR);
  Game_Enter_Idle(0U);

  for (;;) {
    now = Timer_Tick_Count;
    Key_Scan_Process(now);
    command = Uart2_Get_Pressed();
    if (command == '1') {
      Key1_Filter.press_tick = now;
      Key1_Filter.press_event = 1U;
    } else if (command == '2') {
      Key2_Filter.press_tick = now;
      Key2_Filter.press_event = 1U;
    }
    Game_Process(now);
  }
}
