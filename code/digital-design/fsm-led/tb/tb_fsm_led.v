`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/14 08:46:17
// Design Name: 
// Module Name: tb_fsm_led
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_fsm_led();

    // 신호 선언
    reg clk;
    reg rst;
    reg [2:0] sw;
    wire [2:0] led;

    // DUT(Device Under Test) 인스턴스화
    fsm_led DUT (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .led(led)
    );

    // 파형 창(Waveform)에서 상태를 문자(A, B, C, D, E)로 보기 위한 변수 선언
    reg [7:0] state_name; // ASCII 문자 1개 저장용

    // DUT의 current_state 값에 따라 문자 매핑
    always @(*) begin
        case (DUT.current_state)
            3'b000: state_name = "A";
            3'b001: state_name = "B";
            3'b010: state_name = "C";
            3'b011: state_name = "D";
            3'b100: state_name = "E";
            default: state_name = "U"; // Unknown
        endcase
    end

    // 100MHz 클럭 생성 (10ns 주기)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 시뮬레이션 시나리오
    initial begin
        // 초기화
        rst = 1;
        sw = 3'b000;
        #20;
        rst = 0;
        $display("--- Simulation Start: State A ---");

        // 시나리오 1: A -> B -> C -> D -> A (기본 순환)
        #10 sw = 3'b001; // A -> B
        #10 sw = 3'b000; // B 유지 테스트
        #10 sw = 3'b010; // B -> C
        #10 sw = 3'b100; // C -> D
        #10 sw = 3'b000; // D -> A
        #10;
        $display("[%0t ns] Scenario 1 Complete: A->B->C->D->A", $time);

        // 시나리오 2: A -> C -> D -> B -> C (분기 및 유지 테스트)
        #10 sw = 3'b010; // A -> C
        #10 sw = 3'b100; // C -> D
        #10 sw = 3'b001; // D -> B
        #10 sw = 3'b010; // B -> C
        #10;
        $display("[%0t ns] Scenario 2 Complete: A->C->D->B->C", $time);

        // 시나리오 3: C -> D -> E -> A (E 상태 진입 테스트)
        #10 sw = 3'b100; // C -> D
        #10 sw = 3'b111; // D -> E (가장 우측 경로)
        #10 sw = 3'b111; // E 유지 테스트
        #10 sw = 3'b000; // E -> A
        #10;
        $display("[%0t ns] Scenario 3 Complete: C->D->E->A", $time);

        // 시나리오 4: 무어 머신(Moore Machine) 특징 확인 테스트
        // [특징] 무어 머신의 출력은 '현재 상태'에만 의존하므로, 
        // 클럭 사이의 중간(비동기)에 입력(sw)이 막 요동치더라도 출력이 즉시 변하지 않습니다.
        $display("--- Scenario 4: Moore Machine Characteristic Test ---");
        // 초기화 (A상태로)
        sw = 3'b000;
        #30; 
        
        // 클럭 주기 중간(하강 에지)에 비동기적으로 스위치 입력을 바꿔봄!
        @(negedge clk);
        $display("[%0t ns] 클럭 중간에 스위치 입력 변경 (sw = 3'b010)!", $time);
        sw = 3'b010; 
        
        // 2ns 대기 후 출력 확인 (밀리머신이라면 즉시 반응했겠지만, 무어머신이라 안 변함)
        #2;
        $display("[%0t ns] 입력 변경 직후 확인 -> LED 출력: %b (즉시 변하지 않고 유지됨!)", $time, led);
        
        // 다음번 클럭 상승 에지(posedge clk) 도달
        @(posedge clk);
        #1; // 상태 업데이트를 위한 미세 딜레이
        $display("[%0t ns] 클럭 에지 도달 직후 -> State: %s (상태 변경됨)", $time, state_name);
        
        #20;
        
        // 시뮬레이션 종료
        $display("--- Simulation Success & Finished ---");
        $finish;
    end

    // 모니터링: 상태나 LED가 바뀔 때마다 출력
    initial begin
        $monitor("[%0t ns] SW: %b | STATE: %s | LED: %b", $time, sw, state_name, led);
    end

endmodule
