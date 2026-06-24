# 2026-06-07 UVM Adder RAM

## Goal
adder와 RAM DUT를 대상으로 UVM sequence, driver, monitor, scoreboard 구조를 실습한다.

## What I Learned
- UVM testbench는 transaction 단위로 stimulus와 observed data를 주고받는다.
- scoreboard는 DUT 출력과 reference model을 비교하는 중심 역할을 한다.

## Implementation
- `adder.sv`, `ram.sv`와 UVM testbench를 `code/verification/uvm-adder-ram`에 정리했다.
- `sim/filelist.f`와 간단한 `Makefile`을 추가해 시뮬레이션 입력 목록을 분리했다.

## Debugging Note
- `uvm_config_db`로 virtual interface가 전달되는지 확인했다.
- driver와 monitor의 sampling edge가 DUT 동작과 맞는지 점검했다.

## Verification Point
- adder random input의 expected sum과 DUT output을 비교한다.
- RAM write/read sequence에서 같은 address의 data 일치 여부를 확인한다.

## Summary
UVM 검증은 transaction 생성부터 scoreboard 비교까지 데이터 흐름을 끊기지 않게 연결하는 작업이다.
