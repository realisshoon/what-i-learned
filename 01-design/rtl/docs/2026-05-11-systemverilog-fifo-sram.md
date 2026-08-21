# 2026-05-11 SystemVerilog FIFO SRAM

## Goal
SV FIFO와 SRAM testbench를 통해 저장장치 검증 패턴을 확장한다.

## What I Learned
- FIFO는 pointer 경계 조건, SRAM은 address/data 일관성이 중요하다.
- fork/join 같은 SV 동시 실행 구문은 병렬 stimulus 작성에 유용하다.

## Implementation
- `fifo_sv.sv`와 관련 testbench를 `code/systemverilog/fifo-sv`에 정리했다.
- SRAM 관련 `ram_ip.sv`, `tb_sram.sv`, `tb_fork_join.sv`도 메모리 폴더에 보관했다.

## Debugging Note
- write/read가 같은 cycle에 일어나는 조건을 파형으로 확인했다.
- testbench의 비교 시점이 DUT read latency와 맞는지 점검했다.

## Verification Point
- FIFO full/empty, simultaneous read/write, reset case를 확인한다.
- SRAM write-readback loop가 모든 주요 address에서 통과해야 한다.

## Summary
저장장치 검증은 데이터 순서와 주소별 readback을 자동으로 비교하는 구조가 중요하다.
