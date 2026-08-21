/*
 * StopWatch.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */

#ifndef SRC_AP_STOPWATCH_H_
#define SRC_AP_STOPWATCH_H_

#include "../driver/button/Button.h"
#include "../driver/FND/FND.h"
#include "../driver/LED/LED.h"

typedef enum{
	STOP = 0,
	RUN,
	CLEAR
}stopWatchState_e;

void StopWatch_Init();
void StopWatch_Excute();

void StopWatch_RunTime();
void StopWatch_ControlState();
void StopWatch_ControlLed();

void StopWatch_UpdateFnd();
void StopWatch_ClearTime();

void StopWatch_RunLed();
void StopWatch_StopLed();
void StopWatch_ClearLed();

#endif /* SRC_AP_STOPWATCH_H_ */
