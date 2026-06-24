# 2026-06-01 SystemVerilog OOP

## Goal
SystemVerilog class, inheritance, virtual method를 RAM/ALU testbench에 적용한다.

## What I Learned
- class 기반 transaction은 stimulus와 expected result를 함께 들고 다니기 좋다.
- virtual method와 상속을 사용하면 tester 기능을 확장할 수 있다.

## Implementation
- `alu.sv`, `ram.sv`와 OOP 스타일 testbench를 `code/systemverilog/oop-test`에 정리했다.
- randomize 기반 write/read loop와 pass/fail count 구조를 보관했다.

## Debugging Note
- virtual interface 연결 여부를 먼저 확인했다.
- random transaction의 write/read address가 같은지 확인했다.

## Verification Point
- ALU opcode별 expected result를 비교한다.
- RAM write 후 readback 값과 pass/fail counter를 확인한다.

## Summary
SV OOP testbench는 stimulus 생성, driving, checking 역할을 객체로 나누는 연습이다.
