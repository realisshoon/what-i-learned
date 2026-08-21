# SystemVerilog Verification

SystemVerilog OOP 문법과 UVM 이전 단계의 Class-based SystemVerilog Verification을 정리합니다.

## OOP

- [Weapon Inheritance / Polymorphism](oop/weapon-inheritance/) — base class handle에 파생 class object를 대입해 virtual method 동작을 확인합니다.
- [ALU / RAM OOP](oop/alu-ram/) — Transaction과 testbench component를 class로 분리한 실습입니다.

## Class-based Self-checking Testbench

- [UART](../../01-design/protocols/uart/) — Transaction, Generator, Driver, Monitor, Scoreboard, Mailbox를 구성했습니다.
- [Adder](../../01-design/rtl/adder/class-based-sv/) — RTL 주제 아래에 class-based verification source를 함께 보관합니다.

## 확인 가능한 문법과 구조

- class, inheritance, polymorphism, virtual method
- constrained randomization과 `randomize()`
- virtual interface, task/function
- parameterized mailbox와 event synchronization
- Generator → Driver → Monitor → Scoreboard 데이터 흐름

이 항목들은 UVM library를 사용하지 않습니다. 실제 UVM lab은 [UVM Verification Labs](../uvm/)에서 구분해 정리합니다.
