/*
 * StopWatch.c
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */


#include "StopWatch.h"

#define STOP_STATE_LED 5
#define RUN_STATE_LED 7

stopWatchState_e stopWatchState;

uint32_t swHour;
uint32_t swMin;
uint32_t swSec;
uint32_t swTenth;

uint32_t stopWatchLed;
uint32_t stopWatchStateLed;


void StopWatch_Init()
{
	LED_Init();
	FND_init();
	Button_Init();

	stopWatchState = STOP;

    StopWatch_ClearTime();

	stopWatchLed=0x01;
	stopWatchStateLed =(1<<STOP_STATE_LED);

	LED_WritePort8(LED_LOW_GPIO, stopWatchLed);
	LED_WritePort8(LED_HIGH_GPIO, 0x00);

	FND_SetDigits(0, 0, 0, 0, 0);
}

void StopWatch_ClearTime(void)
{
    swHour = 0;
    swMin = 0;
    swSec = 0;
    swTenth = 0;
}


void StopWatch_Excute()
{
	StopWatch_RunTime();
	StopWatch_ControlState();
	StopWatch_UpdateFnd();
	StopWatch_ControlLed();
}

void StopWatch_ControlState()
{
	switch (stopWatchState){
	case STOP:
		if(Button_GetState(&hbtnRunStop)==ACT_PUSHED){
			stopWatchState = RUN;
		}
		else if(Button_GetState(&hbtnClear)==ACT_PUSHED){
			stopWatchState = CLEAR;
		}
		break;
	case RUN:
		if(Button_GetState(&hbtnRunStop)==ACT_PUSHED){
			stopWatchState = STOP;
		}
		break;

	case CLEAR:
		StopWatch_ClearTime();
		StopWatch_ClearLed();
		stopWatchState = STOP;
		break;
	default:
		stopWatchState =STOP;
		break;
	}

}


void StopWatch_RunTime()
{
    static uint32_t prevTime = 0;
    uint32_t curTime = millis();

    if (curTime - prevTime < 100) return;
    prevTime = curTime;

    if (stopWatchState == RUN) {
        swTenth++;

        if (swTenth >= 10) {
            swTenth = 0;
            swSec++;
        }

        if (swSec >= 60) {
            swSec = 0;
            swMin++;
        }

        if (swMin >= 60) {
            swMin = 0;
            swHour++;
        }

        if (swHour >= 24) {
            swHour = 0;
        }
    }
}

void StopWatch_UpdateFnd(void)
{
    uint8_t d3;
    uint8_t d2;
    uint8_t d1;
    uint8_t d0;
    uint8_t dotMask = 0;

    d3 = swMin % 10;
    d2 = swSec / 10;
    d1 = swSec % 10;
    d0 = swTenth;

    if (stopWatchState == RUN) {
        dotMask = 0;

        // digit3 dot: 0.5초 ON / 0.5초 OFF
        if ((millis() / 500) % 2) {
            dotMask |= FND_DOT_DIGIT_3;
        }

        // digit1 dot: 더 빠르게, 0.1초 ON / 0.1초 OFF
        if ((millis() / 100) % 2) {
            dotMask |= FND_DOT_DIGIT_1;
        }
    }
    else if (stopWatchState == CLEAR) {
        dotMask = 0;
    }
    FND_SetDigits(d3, d2, d1, d0, dotMask);
}

void StopWatch_ControlLed(){


	switch (stopWatchState){
	case STOP:
		StopWatch_StopLed();
		break;
	case RUN:
		StopWatch_RunLed();
		break;
	case CLEAR:
		StopWatch_ClearLed();
		break;
	default:
		stopWatchState =STOP;
	}
}

void StopWatch_RunLed()
{

    static uint32_t prevTime = 0;
    uint32_t curTime = millis();

    // HIGH GPIO
    stopWatchStateLed = 0;
    stopWatchStateLed |= (1 << RUN_STATE_LED);
    LED_WritePort8(LED_HIGH_GPIO, stopWatchStateLed);

    // LOW GPIO
    if (curTime - prevTime < 100) return;
    prevTime = curTime;

    stopWatchLed = ((stopWatchLed << 1) | (stopWatchLed >> 7)) & 0xff;
    LED_WritePort8(LED_LOW_GPIO, stopWatchLed);
}
void StopWatch_StopLed()
{
    stopWatchStateLed = 0;
    stopWatchStateLed |= (1 << STOP_STATE_LED);
    LED_WritePort8(LED_HIGH_GPIO, stopWatchStateLed);
}
void StopWatch_ClearLed()
{
    stopWatchLed = 0x01;
    LED_WritePort8(LED_LOW_GPIO, stopWatchLed);

    stopWatchStateLed = 0;
    stopWatchStateLed |= (1 << STOP_STATE_LED);
    LED_WritePort8(LED_HIGH_GPIO, stopWatchStateLed);
}
