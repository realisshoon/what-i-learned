# 2026-04-06 Combinational Logic

## Goal
기본 게이트 동작과 조합논리의 입력-출력 관계를 Verilog로 확인한다.

## What I Learned
- AND, OR, XOR, NOT 같은 기본 게이트는 상태를 저장하지 않고 입력 변화에 바로 반응한다.
- 간단한 DUT도 testbench로 모든 입력 조합을 확인하는 습관이 필요하다.

## Implementation
- `gates.v`에 기본 게이트 조합을 구현했다.
- `tb_gates.v`에서 입력 패턴을 바꿔 출력 변화를 관찰했다.

## Debugging Note
- 신호 이름과 포트 연결이 맞는지 먼저 확인했다.
- 파형에서 입력 변화 후 출력이 조합논리처럼 따라오는지 확인했다.

## Verification Point
- 모든 입력 조합에서 기대 truth table과 출력이 일치해야 한다.
- X/Z 값이 발생하지 않는지 확인한다.

## Summary
조합논리는 저장 상태 없이 현재 입력만으로 출력이 결정된다.
