# 2026-06-28 AXI4-Lite SPI UVM

## Goal
MicroBlaze 전체 SoC가 아니라 `spi_v1_0` custom AXI4-Lite SPI peripheral만 IP-level로 검증하는 UVM 환경을 구성한다.

## What I Learned
- AXI4-Lite peripheral 검증은 SoC 전체를 올리지 않아도 register access와 serial bus 관찰만으로 핵심 동작을 확인할 수 있다.
- SPI master DUT의 MOSI 동작은 AXI `TXDATA` write와 SPI monitor의 reconstructed byte를 비교해서 self-checking할 수 있다.
- Verdi/vdCov의 빨간 coverage item은 실패가 아니라 아직 실행되지 않은 code/branch/toggle/FSM item을 의미한다.
- UVM/Verdi recorder code는 tool instrumentation이므로 DUT coverage closure 대상에서 제외하는 것이 좋다.

## Implementation
- `code/protocol/axi4-lite-spi-uvm`에 AXI4-Lite SPI peripheral RTL과 UVM testbench를 정리했다.
- DUT RTL은 `spi_v1_0.v`, `spi_v1_0_S00_AXI.v`, `spi_master.v`로 구성했다.
- `spi_slave.sv`는 DUT가 아니라 testbench용 SPI slave response model로 사용했다.
- UVM 구성은 AXI-Lite driver/monitor, SPI monitor, scoreboard, coverage, env, test, `tb_top`으로 분리했다.

## Verification Scenario
- Reset 후 `TXDATA` register에 data를 write한다.
- `CR.START`와 `CLK_DIV`를 write해서 SPI transfer를 시작한다.
- `SR.DONE`이 set될 때까지 polling한다.
- `RXDATA`를 read하고, SPI monitor가 복원한 MOSI/MISO byte와 scoreboard에서 비교한다.

## Directed Tests
- `TXDATA = 8'h00`
- `TXDATA = 8'hFF`
- `TXDATA = 8'hA5`
- `TXDATA = 8'h5A`
- random TX values

## Coverage
- Functional coverage는 `TXDATA`, START write, DONE status, SPI transaction complete를 covergroup으로 확인한다.
- Code coverage는 `cov_hier.cfg`의 `+tree tb_top.dut` 설정으로 DUT hierarchy만 집계한다.
- Verdi coverage viewer는 `make cov` 후 `make vdcov`로 확인한다.

## Debugging Note
- VCS macro 안에서 여러 string literal을 C 스타일로 이어 붙이면 syntax error가 날 수 있어 `{ "...", "..." }` concatenation을 사용했다.
- Verdi recorder coverage가 낮게 보이는 것은 DUT 문제가 아니므로 `-cm_hier` filter로 제외했다.
- `filelist.f`는 UVM class 파일을 직접 컴파일하지 않고 `tb_top.sv` package include 경로로 정리했다.

## Summary
AXI4-Lite register access와 SPI serial waveform을 UVM scoreboard로 연결하면, custom SPI peripheral을 SoC 없이도 발표 가능한 수준으로 검증할 수 있다.
