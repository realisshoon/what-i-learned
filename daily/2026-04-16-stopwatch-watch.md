# 2026-04-16 Stopwatch Watch

## Goal
stopwatch와 watch 기능을 datapath/control 구조로 나누어 구현한다.

## What I Learned
- 복합 기능은 datapath와 control unit을 분리하면 모드별 동작을 추적하기 쉽다.
- 입력 버튼은 debounce와 edge 처리 후 내부 제어 신호로 쓰는 편이 안전하다.

## Implementation
- stopwatch/watch datapath, control unit, top, input controller를 정리했다.
- 주요 단위 testbench를 함께 보관해 기능별 검증 포인트를 분리했다.

## Debugging Note
- 100Hz tick과 FND refresh timing을 구분해서 확인했다.
- mode 전환 시 내부 카운터가 의도대로 유지/초기화되는지 봤다.

## Verification Point
- reset, start/stop, mode 변경, watch increment 조건을 확인한다.
- FND 출력과 내부 시간 값이 일치해야 한다.

## Summary
시간 기반 설계는 tick 생성, 상태 제어, 표시 출력을 분리해서 검증한다.
