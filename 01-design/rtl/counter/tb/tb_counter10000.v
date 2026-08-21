`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 18:48:26
// Design Name: 
// Module Name: tb_counter10000
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


module tb_counter10000();

    reg clk;
    reg rst;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // FND Scan 시간과 Tick 시간이 적절히 보이도록 파라미터 튜닝
    // SCAN_MAX(2) -> FND스캔 1주기(o_1khz) = 40ns
    // TICK_MAX(100) -> 1 tick = 1,000ns
    // 그러면 1틱 오르기 전에 FND가 모든 자릿수(4개)를 여러번 스캔완료합니다!
    counter_10000 #(
        .TICK_MAX(100),
        .SCAN_MAX(2)
    ) dut (
        .clk(clk),
        .rst(rst),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    always #30 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        
        #20;
        rst = 0;

        // 1000틱이 오르려면 1틱(1,000ns) x 1000 = 1,000,000ns 필요
        // 조금 더 여유를 두어 1,100,000 ns 동안 시뮬레이션
        #1_100_000;
        $stop;
    end

endmodule
