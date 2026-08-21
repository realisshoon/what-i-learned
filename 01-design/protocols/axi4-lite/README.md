# AXI4-Lite Master / Slave RTL

AXI4-Lite Master/Slave RTL을 작성하고 독립적인 write/read channel handshake를 SystemVerilog TB로 확인했습니다.

## 한눈에 보기

- Write flow: AW → W → B
- Read flow: AR → R
- VALID / READY handshake
- channel별 FSM
- Master/Slave integration TB
- Xilinx custom IP template variant

## RTL Design

Master는 AW, W, B, AR, R channel에 각각 상태를 두고 handshake 완료 조건을 추적합니다. Slave는 write address와 data가 서로 다른 cycle에 도착하는 경우를 저장한 뒤 response를 생성합니다.

Transfer는 VALID와 READY가 동시에 1인 cycle에 완료됩니다. 이 실습은 보존된 RTL과 testbench의 동작 범위를 설명하며 AXI4-Lite 전체 compliance를 보장하지 않습니다.

## Verification

- `tb_axi4_lite_master_slave.sv`에서 Master와 Slave를 연결해 write/read flow를 구동합니다.
- `tb_myip_axi_slave.sv`에서 custom IP slave template의 register access를 확인합니다.
- 이번 README 작성 단계에서는 simulation을 다시 실행하지 않았습니다.

## Repository Structure

```text
axi4-lite/
├── rtl/          # Master / Slave RTL
├── tb/           # SystemVerilog TB
├── ip-template/  # Xilinx custom IP wrapper RTL
├── template/     # slave TB template
└── docs/         # 학습 기록
```
