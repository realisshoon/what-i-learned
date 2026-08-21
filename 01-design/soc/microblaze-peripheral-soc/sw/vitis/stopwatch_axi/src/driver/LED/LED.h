

#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include "../../HAL/GPIO/GPIO.h"
#include <stdint.h>

#define LED_LOW_GPIO 		GPIOC
#define LED_HIGH_GPIO 		GPIOD

void LED_Init();
void LED_WritePort8(GPIO_TypeDef *LedGPIOx, uint16_t led);
void LED_WritePort16( uint16_t led);
void LED_PinON(uint16_t ledPin);
void LED_PinOFF(uint16_t ledPin);
void LED_PINTOGGLE(uint16_t ledPin);




#endif /* SRC_DRIVER_LED_LED_H_ */
