# UART / Sensor / Stopwatch FPGA Integration

UART와 FIFO를 중심으로 SR04, DHT11, Watch/Stopwatch datapath와 FND 표시를 연결한 FPGA integration lab입니다.

## 한눈에 보기

- UART TX/RX와 baud tick
- FIFO 기반 byte buffering
- SR04 distance measurement
- DHT11 temperature/humidity data path
- Watch / Stopwatch control과 counter
- FND display와 Basys3 constraints

## System 구성

`uart_sensor_watch` top에서 UART command/data path, sensor data, Watch/Stopwatch state와 display selection을 연결합니다. FIFO와 ASCII encoder/decoder가 serial byte와 내부 control/data 사이를 중계합니다.

## 주요 Module

- `uart.v` — UART TX/RX와 baud tick
- `ascii_decoder_sender.v` — ASCII command decode와 sensor/status 전송
- `sr04_controller.v` / `dht11_datapath.v` — sensor timing과 data 변환
- `watch_datapath.v` / `stopwatch_datapath.v` — time counter
- `control_unit*.v` — mode, sensor, display, Watch/Stopwatch 제어
- `fnd_controller.v` — FND scan과 표시 data 선택

## Verification

보존된 testbench는 SR04와 DHT11 sensor interface를 단위 수준에서 구동합니다. 전체 integration top을 self-checking하는 testbench는 현재 directory에 없습니다.

## Repository Structure

```text
uart-sensor-stopwatch/
├── rtl/          # 통합 RTL과 하위 module
├── tb/           # sensor interface testbench
└── constraints/  # Basys3 constraints
```
