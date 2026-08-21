
#include "xil_printf.h"
#include "common/delay/delay.h"
#include "ap/StopWatch.h"


int main()

{

	StopWatch_Init();

	while(1){

		StopWatch_Excute();

		FND_Execute();
		incTick();
		delay_ms(1);   // 0.5 ON
	}

	return 0;

}
