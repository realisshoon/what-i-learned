# 2026-05-28 RV32I Multicycle

## Goal
RV32I CPU를 multicycle 구조로 나누어 control FSM과 datapath 흐름을 구현한다.

## What I Learned
- multicycle CPU는 fetch, decode, execute, memory, writeback 단계를 상태로 분리한다.
- single-cycle보다 cycle 수는 늘지만 한 cycle의 조합 경로 부담을 줄일 수 있다.

## Implementation
- `multi_cpu.sv`, `multi_control_unit.sv`, `multi_datapath.sv`를 multicycle 폴더에 정리했다.
- ROM/RAM과 `tb_rv32i_multi.sv`를 함께 보관했다.

## Debugging Note
- state별 제어신호가 이전 cycle 값에 의해 오염되지 않는지 확인했다.
- instruction register와 memory data register 갱신 시점을 점검했다.

## Verification Point
- 각 명령이 예상 state sequence를 따라야 한다.
- PC, IR, register writeback이 올바른 cycle에만 갱신되어야 한다.

## Summary
multicycle CPU 검증은 명령 결과뿐 아니라 state sequence 자체도 검증 대상이다.
