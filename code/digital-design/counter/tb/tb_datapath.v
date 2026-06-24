`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 16:17:26
// Design Name: 
// Module Name: tb_datapath
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


module tb_datapath();

    reg clk;
    reg rst;
    wire [13:0] tick_counter;
    
    // 시뮬레이션 시간을 줄이기 위해 100,000,000 / 10 대신 10으로 파라미터 오버라이딩합니다.
    // 1 tick = 10클럭 (100ns)
    datapath #(
        .TICK_MAX(10) 
    ) dut(
        .clk(clk),
        .rst(rst),
        .tick_counter(tick_counter)
    );

    always #5 clk = ~clk; // 100MHz (10ns base) 주기 생성

    initial begin
        clk = 0;
        rst = 1;
        
        #20;
        rst = 0;

        // 1000의 자리가 동작하는 것을 보려면 1000번의 tick이 발생해야 합니다.
        // 현재 설정에서 1 tick = 100ns 이므로, 1000 tick은 100,000ns 입니다.
        // 충분히 파형을 볼 수 있도록 120,000ns 동안 시뮬레이션을 진행합니다.
        #120_000;
        
        $stop;
    end

endmodule
