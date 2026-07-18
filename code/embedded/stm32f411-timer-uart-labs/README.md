# STM32F411 Timer / UART 과제 정리

STM32F411에서 타이머 인터럽트와 UART를 이용해 작성한 Bare-metal C 과제 3개를 정리한다. 세 프로젝트 모두 STM32 HAL을 사용하지 않으며, CMSIS 디바이스 헤더를 바탕으로 RCC, GPIO, TIM, USART, NVIC 레지스터를 직접 제어한다.

## 디렉터리 구조

| 디렉터리 | 과제 |
| --- | --- |
| 1101-led-ping-pong/ | TIM4 인터럽트 기반 LED Ping-Pong |
| 1102-reaction-time-test/ | 5 ms TIM4 tick 기반 Reaction Time Test |
| 1103-uart-cli-controller/ | USART2 RX 인터럽트 기반 UART CLI Controller |

각 디렉터리는 시작 코드(crt0.s), 링커 스크립트, CMSIS/STM32F411 헤더, 드라이버 소스와 Makefile을 포함하는 독립 빌드 프로젝트다. .o, .elf, .bin, .map, __dump*.txt 같은 생성물은 포함하지 않는다.

## 공통 핀 배치

| 기능 | 핀 | 설정 |
| --- | --- | --- |
| LED1 / LED2 / LED3 | PA5 / PA6 / PA7 | GPIO 출력 |
| Key1 | PC13 | Active-low GPIO 입력 |
| Key2 | PC7 | Active-low GPIO 입력, 내부 pull-up |
| USART2 TX / RX | PA2 / PA3 | AF7, 115200 baud |

시스템 클럭은 96 MHz다. 과제 B와 C의 TIM4 인터럽트 주기는 5 ms다.

## 과제 A: Timer Interrupt 기반 LED Ping-Pong

### 목표와 구조

LED가 LED1 → LED2 → LED3 → LED2 → LED1 순서로 반복한다. 초기 주기는 500 ms이며 UART 명령으로 약 100 ms~1 s 범위에서 속도를 바꾸거나 정지/재개한다. Main은 UART를 non-blocking polling하고 TIM4 event가 있을 때만 LED 상태를 갱신한다.

### 상태 머신

| 현재 상태 | 이벤트 | 다음 동작 |
| --- | --- | --- |
| LED1, 오른쪽 진행 | TIM4 event | LED2 |
| LED2, 오른쪽 진행 | TIM4 event | LED3, 방향 반전, [PONG] 예약 |
| LED3, 왼쪽 진행 | TIM4 event | LED2 |
| LED2, 왼쪽 진행 | TIM4 event | LED1, 방향 반전, [PING] 예약 |
| 실행 중 | s | TIM4 정지, event flag 제거 |
| 정지 중 | s | 현재 ARR로 TIM4 재시작 |

TIM4_IRQHandler()는 update flag를 지운 뒤 Timer_Event_Flag만 설정한다. LED 제어, 상태 전이, [PING]/[PONG] 출력은 Main에서 처리한다.

### UART 명령과 테스트

| 명령 | 동작 |
| --- | --- |
| u | ARR을 줄여 속도 증가 |
| d | ARR을 늘려 속도 감소 |
| s | 정지/재시작 toggle |

115200 baud 터미널을 열고 LED 왕복, 양 끝 메시지, u/d 속도 범위, s 정지/재시작을 확인한다.

## 과제 B: Reaction Time Test

### 목표와 구조

Key1으로 시작하고 1~4초의 무작위 대기 후 LED 신호가 켜지면 Key2로 반응 시간을 잰다. 16-bit LFSR에 현재 tick과 free-running TIM4->CNT 값을 섞어 대기 시간을 만든다. 입력은 5 ms마다 sampling하며 4개 연속 sample로 약 20 ms debounce와 press edge detection을 적용한다.

### 상태 머신

| 상태 | 동작과 전이 |
| --- | --- |
| IDLE | LED를 500 ms마다 점멸한다. Key1 press → RANDOM_WAIT |
| RANDOM_WAIT | LED OFF, 1~4초 대기. 신호 전 Key2 → FOUL, 시간 만료 → REACTION |
| REACTION | LED ON. Key2 press tick으로 반응 시간 계산 → RESULT |
| RESULT | 결과를 2초 유지한 뒤 IDLE |
| FOUL | Foul Play!를 표시하고 2초 뒤 IDLE |

TIM4_IRQHandler()는 Timer_Tick_Count만 증가시킨다. debounce, 난수 생성, 상태 전이, LED/UART 처리는 Main에서 수행한다.

### UART 입력과 테스트

| 입력 | 테스트 동작 |
| --- | --- |
| 1 | Key1 press event |
| 2 | Key2 press event |

Key1 또는 1로 시작하고 PRESS KEY NOW! 이후 Key2 또는 2를 눌러 5 ms 단위 결과를 확인한다. 무작위 대기 중 Key2/2를 입력해 Foul Play!가 출력되는지, 실제 키를 길게 눌러도 press event가 한 번만 발생하는지 확인한다.

## 과제 C: UART CLI Controller

### 목표와 구조

USART2 RX interrupt로 명령 한 줄을 받고 Main에서 tokenize, parsing, 실행한다. 수신 버퍼는 null 문자를 포함한 64 byte 고정 배열이므로 payload는 최대 63 byte다.

RX ISR은 문자 수신, 버퍼 저장, Enter 감지, line_complete/overflow 기록만 한다. CR 다음 LF는 ignore_lf로 버려 CRLF 중복 실행을 막는다. overflow 발생 시 Main이 Command too long.을 출력하고 수신 상태를 초기화한다.

### 명령 처리와 Timer 상태 머신

| 상태/단계 | 역할 |
| --- | --- |
| RX 수신 | ISR이 문자를 버퍼에 저장 |
| line complete | ISR이 CR/LF를 감지해 flag 설정 |
| Main parsing | 공백 기준 tokenize 후 명령/인자 검증과 실행 |
| TIMER_IDLE | 새 timer 명령을 받을 수 있음 |
| TIMER_WAIT | 지정한 1~60초를 non-blocking 대기 |
| TIMER_BLINK_ON | LED 3개를 500 ms ON |
| TIMER_BLINK_OFF | LED 3개를 500 ms OFF, ON/OFF 한 쌍을 총 3회 완료 후 IDLE |

TIM4_IRQHandler()는 5 ms마다 Timer_Tick_Count만 증가시킨다. 타이머 대기와 정확히 3회의 ON/OFF 쌍은 Main 상태 머신에서 처리한다.

### 지원 명령

| 명령 | 동작 |
| --- | --- |
| help | 명령 목록 |
| led on [1-3] | 지정 LED ON |
| led off [1-3] | 지정 LED OFF |
| status | LED 3개와 Key1/Key2 상태 |
| timer [1-60] | 지정 시간 후 LED 3개를 ON/OFF 한 쌍 기준 3회 점멸 |

정상/오류 인자, CR/LF/CRLF, 63자 초과 명령을 시험한다. timer 1 실행 중 status가 처리되는지와 대기 후 세 번의 ON/OFF 쌍도 확인한다.

## 빌드 방법

Makefile은 Windows용 ARM GNU Toolchain 15.2.1과 GNU Make를 사용하며 기본 TOOL_DIR는 다음과 같다.

    C:\Program Files\01.GCC_Compiler_for_ARM\arm-gnu-toolchain-15.2.rel1-mingw-w64-i686-arm-none-eabi

다른 위치에 설치했다면 각 Makefile의 TOOL_DIR와 필요 시 VERSION을 수정한다.

    cd code\embedded\stm32f411-timer-uart-labs\1101-led-ping-pong
    make

    cd ..\1102-reaction-time-test
    make

    cd ..\1103-uart-cli-controller
    make

성공 시 rom_0x08000000.elf, .bin, .map과 dump 파일이 생성되며 모두 .gitignore 대상이다. STM32CubeProgrammer CLI가 PATH에 있다면 make run으로 SWD flash할 수 있다.
