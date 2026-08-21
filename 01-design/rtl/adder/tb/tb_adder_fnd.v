`timescale 1ns / 1ps

module tb_adder_fnd();

    // 1. 입력 신호 (가짜 스위치 및 클럭) -> reg 선언
    reg clk;
    reg rst;
    reg [7:0] a;
    reg [7:0] b;

    // 2. 출력 신호 (결과 관찰용) -> wire 선언
    wire [7:0] fnd_data;
    wire [3:0] fnd_com;
    wire led;

    // 3. 검증할 전체 완성품 (Top Module) 연결
    adder_fnd dut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com),
        .led(led)
    );

    // 4. 메인 클럭(Clock) 생성: 100MHz (주기 10ns)
    always #5 clk = ~clk; 

    // 5. 테스트 시나리오
    initial begin
        // --- [초기화] ---
        clk = 0;
        rst = 1;  // 시스템 리셋 활성화
        a = 8'd0;
        b = 8'd0;

        #100;     
        rst = 0;  // 리셋 해제 (정상 동작 시작)
        #100;     

        // --- [Test Case 1] 100 + 25 = 125 ---
        // 예상 결과: 가산기 내부 w_sum = 125, led = 0
        // FND 출력: 0 -> 1 -> 2 -> 5 가 순차적으로 깜빡임
        a = 8'd100;
        b = 8'd25;
        // 시뮬레이션에서 FND가 한 바퀴(4자리) 다 도는 것을 보려면 최소 4ms(4,000,000ns)가 필요합니다!
        #5000000;    

        // --- [Test Case 2] 200 + 55 = 255 ---
        // 예상 결과: 가산기 내부 w_sum = 255, led = 0
        // FND 출력: 0 -> 2 -> 5 -> 5 가 순차적으로 깜빡임
        a = 8'd200;
        b = 8'd55;
        #5000000;

        // --- [Test Case 3] 255 + 5 = 260 (오버플로우 테스트) ---
        // 8비트 최대치인 255를 넘었으므로 256의 자리는 버려지고 4만 남음
        // 예상 결과: 가산기 내부 w_sum = 4, led = 1 (오버플로우 발생)
        // FND 출력: 0 -> 0 -> 0 -> 4 가 순차적으로 깜빡임
        a = 8'd255;
        b = 8'd5;
        #5000000;

        $finish; // 시뮬레이션 깔끔하게 종료
    end

endmodule