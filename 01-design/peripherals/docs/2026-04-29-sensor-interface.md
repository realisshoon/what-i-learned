# 2026-04-29 Sensor Interface

## Goal
SR04와 DHT11 같은 외부 센서 인터페이스의 타이밍 제어를 실습한다.

## What I Learned
- 센서 인터페이스는 프로토콜별 pulse width와 wait state를 FSM으로 표현할 수 있다.
- testbench에서 외부 센서 응답을 모델링해야 DUT 동작을 확인할 수 있다.

## Implementation
- `sr04_controller.v`와 `dht11.v`를 `code/sensor-interface` 아래에 분리했다.
- 각 센서 testbench와 표시/입력 helper를 함께 정리했다.

## Debugging Note
- trigger/echo, request/response 구간의 시간 단위를 파형에서 확인했다.
- wait counter 폭과 timeout 조건을 점검했다.

## Verification Point
- 정상 응답, 응답 지연, timeout case를 확인한다.
- 측정값이 표시 모듈로 전달되는 조건을 확인한다.

## Summary
센서 인터페이스는 외부 타이밍을 내부 FSM과 카운터로 안정적으로 받아내는 설계다.
