# Adder UVM Labs

작은 Adder DUT에 UVM 기본 component를 적용하고 Analysis Port, Subscriber 연결로 확장한 학습 source입니다.

## 학습 흐름

### [Basic Environment](basic-environment/)

Sequence Item, Sequence, Driver, Monitor, Scoreboard, Agent, Environment, Test를 한 파일 중심으로 구성했습니다. Standalone Adder와 Adder/RAM combined variant를 함께 보존합니다.

교육 서버에서 복구한 VCS log에는 Scoreboard PASS 100건과 `UVM_ERROR 0`, `UVM_FATAL 0`이 기록되어 있습니다.

### [Analysis Port Practice](analysis-port-practice/)

하나의 Monitor가 Analysis Port를 통해 두 component, Subscriber, Scoreboard로 transaction을 전달하도록 구성했습니다.

## 현재 상태

Analysis Port practice의 Makefile은 `rtl/adder.sv`를 참조하지만 해당 clocked Adder DUT를 repository와 server backup에서 찾지 못했습니다. Basic combinational Adder는 interface가 달라 대체하지 않았으며 상태를 `RECOVERY_NEEDED`로 유지합니다.

복구된 Analysis Port log에는 PASS 출력과 모순되는 최종 문구가 함께 있어 신뢰할 수 있는 PASS evidence로 사용하지 않습니다. 현재 Windows 환경에서도 다시 실행하지 않았습니다.
