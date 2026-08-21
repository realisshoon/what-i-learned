# RAM UVM Labs

RAM read/write 동작에 UVM 기본 환경을 적용하고 component 분리와 Functional Coverage로 확장했습니다.

## 학습 흐름

### [Basic Environment](basic-environment/)

단일 SystemVerilog TB에 Sequence Item, Driver, Monitor, Scoreboard, Agent, Environment와 Test를 구성했습니다.

교육 서버에서 복구한 VCS log에는 read comparison PASS 49건과 `UVM_ERROR 0`, `UVM_FATAL 0`이 기록되어 있습니다.

### [Layered Environment](layered-environment/)

Interface, package, Sequence Item, Sequence, Driver, Monitor, Agent, Scoreboard, Coverage, Environment, Test를 파일별로 분리했습니다. `ram_coverage`는 `uvm_subscriber`를 상속하고 covergroup으로 read/write transaction을 sampling합니다.

## 현재 상태

Layered Environment source와 VCS/Verdi Makefile은 보존되어 있지만 신뢰할 수 있는 simulation PASS log는 확인하지 못했습니다. 현재 Windows 환경에서도 다시 실행하지 않았습니다.
