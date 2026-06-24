# 2026-04-28 Memory FIFO

## Goal
FIFO, RAM, register의 기본 저장 구조를 구현하고 testbench로 확인한다.

## What I Learned
- FIFO는 write/read pointer와 full/empty 조건이 핵심이다.
- RAM은 write enable, address, read data timing을 명확히 해야 한다.

## Implementation
- `fifo.v`, `ram.v`, `register_8bit.v`, `ram_ip.sv`를 메모리 관련 폴더로 정리했다.
- FIFO/RAM/register testbench를 함께 이동했다.

## Debugging Note
- full/empty 경계 조건에서 pointer가 잘못 증가하지 않는지 확인했다.
- RAM read latency가 testbench 비교 시점과 맞는지 확인했다.

## Verification Point
- FIFO empty read, full write, wrap-around 조건을 확인한다.
- RAM write 후 같은 address readback 값이 일치해야 한다.

## Summary
메모리류 검증은 경계 조건과 read/write 타이밍이 승부처다.
