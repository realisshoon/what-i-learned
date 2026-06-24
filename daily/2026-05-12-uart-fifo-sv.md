# 2026-05-12 UART FIFO SV

## Goal
UART와 FIFO를 SystemVerilog 기반으로 연결하고 ASCII 송수신 흐름을 검증한다.

## What I Learned
- protocol block과 buffer block을 연결하면 backpressure와 valid timing 확인이 필요하다.
- ASCII 변환 같은 주변 로직도 단위 testbench로 분리하면 디버깅이 쉽다.

## Implementation
- `uart_sv.sv`, `fifo_sv.sv`, `uart_ascii_sv.sv`, `uart_rx_fifo_sv_top.sv`를 UART 폴더에 정리했다.
- UART/FIFO/ASCII 통합 testbench를 함께 보관했다.

## Debugging Note
- RX FIFO write timing과 ASCII decode timing이 어긋나지 않는지 확인했다.
- 중복된 제출 폴더와 Vivado source 폴더 중 Vivado source 쪽을 우선 사용했다.

## Verification Point
- UART RX 데이터가 FIFO에 순서대로 저장되어야 한다.
- ASCII 변환 결과와 FIFO pop data가 기대값과 일치해야 한다.

## Summary
UART+FIFO 통합 검증은 byte 흐름의 순서와 valid timing을 끝까지 추적하는 일이다.
