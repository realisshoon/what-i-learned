`timescale 1ns / 1ps

module tb_clk_div();

    // 1. 입력 (우리가 조작할 스위치)
    reg clk;
    reg rst;

    // 2. 출력 (파형으로 관찰할 결과)
    wire o_1khz; // 출력 포트 이름이 다르면 본인 코드에 맞게 수정하세요!

    // 3. 검증할 부품 (DUT) 연결
    // 본인이 작성한 클럭 분주기 모듈 이름으로 맞추세요. (예: clk_div_1khz)
    clk_div_1khz dut (
        .clk(clk),
        .rst(rst),
        .o_1khz(o_1khz)
    );

    // 4. 메인 클럭 100MHz 생성 (5ns마다 반전 = 10ns 주기)
    always #5 clk = ~clk;

    // 5. 시뮬레이션 시나리오
    initial begin
        // 초기화
        clk = 0;
        rst = 1;  // 처음에는 리셋을 걸어줍니다. (시스템 초기화)

        #20;
        rst = 0;  // 20ns(클럭 2번 주기) 뒤에 리셋을 해제하여 동작을 시작합니다.

        // 클럭이 분주되는 것을 관찰하기 위해 충분히 기다립니다.
        // MAX_COUNT를 '5'나 '10'으로 줄였다면 500ns 정도면 충분합니다.
        #500; 

        // 시뮬레이션 종료
        $finish;
    end

endmodule