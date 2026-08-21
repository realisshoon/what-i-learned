/*
 * FND.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_FND_FND_H_
#define SRC_DRIVER_FND_FND_H_


#include "../../HAL/GPIO/GPIO.h"
#include <stdint.h>

#define FND_DATA_GPIO 			GPIOA
#define FND_COM_GPIO 			GPIOB

#define FND_DIGIT_0 			0
#define FND_DIGIT_1 			1
#define FND_DIGIT_2 			2
#define FND_DIGIT_3 			3

#define FND_DOT_DIGIT_0        (1 << FND_DIGIT_0)
#define FND_DOT_DIGIT_1        (1 << FND_DIGIT_1)
#define FND_DOT_DIGIT_2        (1 << FND_DIGIT_2)
#define FND_DOT_DIGIT_3        (1 << FND_DIGIT_3)

void FND_init();
void FND_Execute();

void FND_SetDigits(uint8_t d3, uint8_t d2, uint8_t d1, uint8_t d0, uint8_t dotMask);
void FND_SetNum(uint32_t num);
void FND_SetDotMask(uint8_t dotMask);


#endif /* SRC_DRIVER_FND_FND_H_ */
