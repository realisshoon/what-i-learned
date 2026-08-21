# RISC-V RV32I Architecture Labs

RV32I datapath 준비 단계에서 Single Cycle CPU를 구현하고, Multi Cycle 구조와 APB integration으로 확장했습니다.

## 한눈에 보기

- RV32I instruction decode와 datapath/control 분리
- Single Cycle CPU
- Multi Cycle control FSM
- ROM/RAM 연결
- APB Master와 memory access
- SystemVerilog TB

## 구현 흐름

1. [Prep](prep/) — general register와 datapath 기본 구조
2. [Single Cycle](single-cycle/) — 한 cycle에 fetch부터 writeback까지 수행하는 RV32I CPU
3. [Multi Cycle](multi-cycle/) — fetch, decode, execute, memory, writeback을 control state로 분리
4. [APB Integration](apb/) — CPU load/store 요청을 APB transaction으로 변환

## Architecture

Single Cycle 구조는 control unit이 instruction field를 decode해 ALU, register file, memory와 PC 경로를 제어합니다. Multi Cycle 구조는 같은 동작을 여러 state로 나누고 `pc_en`을 포함한 state별 control signal을 생성합니다.

APB variant는 CPU의 read/write request를 `APB_Master`에 연결합니다. `PSEL`, `PENABLE`, `PREADY`로 setup/access phase를 구성하고 BRAM interface를 함께 보존합니다.

## Verification / 현재 상태

| 단계 | 보존 및 확인 상태 |
|---|---|
| Single Cycle | compile 확인. 현재 source는 `pc_en` 연결 revision이 맞지 않아 elaboration이 완료되지 않음 |
| Multi Cycle | Vivado compile/elaboration 확인 |
| APB Master TB | Vivado compile/elaboration 확인 |
| Full APB SoC | `rom.sv`가 참조하는 `rom_code.mem`을 원본 project에서 복구하지 못함 |

확인되지 않은 module이나 memory image를 임의로 대체하지 않고 원본 학습 source 상태를 유지합니다.

## Repository Structure

```text
rv32i/
├── prep/          # datapath 준비 실습
├── single-cycle/  # Single Cycle CPU
├── multi-cycle/   # Multi Cycle CPU와 control FSM
├── apb/           # APB integration
└── docs/          # 단계별 학습 기록
```
