`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/07 13:21:37
// Design Name: 
// Module Name: tb_full_adder_4bit
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


module tb_full_adder_4bit ();
    // 1. 변수 선언: a와 동일하게 b도 4비트여야 합니다!
    reg [3:0] a;
    reg [3:0] b;
    reg cin;
    wire [3:0] sum;
    wire cout;

    integer i, j;
    // 2. DUT 인스턴스 및 포트 매핑
    // 4비트 변수 전체를 한방에 연결할 수 있으므로, .a(a[0]) 처럼 한 자리씩 나눌 필요가 없습니다!
    full_adder_4bit dut (
        .a   (a),    // 4비트 선 묶음 a를 통째로 연결
        .b   (b),    // 4비트 선 묶음 b를 통째로 연결
        .cin (cin),  // 1비트 cin 연결
        .sum (sum),  // 4비트 선 묶음 sum 통째로 연결
        .cout(cout)  // 1비트 cout 연결
    );


    // 3. 반복문을 이용한 모든 경우의 수 시뮬레이션
    initial begin
        cin = 1'b0;  // 올림수 입력은 일단 0으로 고정해 둡니다.

        // a에 들어갈 숫자 (0~15)
        for (i = 0; i < 16; i = i + 1) begin

            // a가 바뀔 때마다 b의 숫자 (0~15)를 또 모두 테스트
            for (j = 0; j < 16; j = j + 1) begin
                a = i;  // i값을 4비트 a에 자동으로 맞춰서 넣음 (ex: i가 5면 a는 0101)
                b = j;  // j값을 4비트 b에 넣음
                #10;  // 넣고 나서 10 나노초 대기
            end

        end

        // 시뮬레이션 종료
        $finish;
    end
endmodule
