# 2026-05-07 SystemVerilog Adder

## Goal
SystemVerilog 문법과 간단한 class/interface 기반 testbench를 adder에 적용한다.

## What I Learned
- interface를 사용하면 DUT와 testbench 사이 신호 묶음을 명확히 전달할 수 있다.
- class와 randomize를 사용하면 반복 입력 생성이 쉬워진다.

## Implementation
- `adder.sv`와 SV testbench 파일을 `code/systemverilog/adder-sv`에 정리했다.
- transaction, generator 형태의 테스트 코드 후보를 함께 보관했다.

## Debugging Note
- randomize 결과가 DUT 입력에 실제로 drive되는지 확인했다.
- SV 파일과 Verilog 파일의 compile order를 구분했다.

## Verification Point
- 랜덤 입력에서 sum/carry expected value와 DUT 출력이 일치해야 한다.
- mode 신호가 있는 경우 add/sub 동작을 모두 확인한다.

## Summary
SystemVerilog testbench는 구조화된 stimulus와 자동 비교로 반복 검증을 단순하게 만든다.
