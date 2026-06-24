`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/14 14:34:19
// Design Name: 
// Module Name: tb_set_det_mealy
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


module tb_set_det_mealy();

    // 신호 선언
    reg clk;
    reg rst;
    reg din_bit;
    wire dout_bit;

    // DUT 인스턴스화
    set_det_mealy DUT (
        .clk(clk),
        .rst(rst),
        .din_bit(din_bit),
        .dout_bit(dout_bit)
    );

    // 클럭 생성 (100MHz, 10ns 주기)
    always #5 clk = ~clk;

    // 시뮬레이션 시나리오
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        din_bit = 0;
        
        #15;
        rst = 0;
        
        $display("--- Simulation Start ---");

        // 시나리오 1: 001001 (0 -> 1 -> 0 -> 0 -> 1 -> 0)
        // 예상: 0 -> 0 -> 0 -> 0 -> 0 -> 1
        #5 din_bit = 1;
        #30 din_bit = 0;
        #10 din_bit = 1;
        #20 din_bit = 0;
        #40 din_bit = 1;
        #10 din_bit = 0;
        #30 din_bit = 1;
        #40 din_bit = 0;
        #10 din_bit = 1;
        #10 din_bit = 0;
        #30 din_bit = 1;
        #20 din_bit = 0;
        #100

        // 시뮬레이션 종료
        $display("--- Simulation Success & Finished ---");
        $finish;
    end

    // 모니터링
    initial begin
        $monitor("[%0t ns] din_bit: %b | dout_bit: %b", $time, din_bit, dout_bit);
    end

endmodule
