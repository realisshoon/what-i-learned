`timescale 1ns / 1ps

module tb_counter_10000();

    reg clk;
    reg rst;
    reg [2:0] sw;
    
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // 모듈 인스턴스화
    counter_10000 U_DUT (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    // 100MHz 클럭 생성 (주기 10ns)
    always #5 clk = ~clk;

    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        sw = 3'b000;
        #20;
        
        rst = 0;
        
        // 1. 동작 시작 (run_stop = 1, clear = 0, mode = 0: Up count)
        sw = 3'b001; 
        
        // 10Hz tick을 보기 위해서는 매우 긴 시간이 필요하지만,
        // 검증을 위해 일정 시간 동안만 시뮬레이션 합니다.
        #10000;
        sw = 3'b000;
        #10000;
        sw = 3'b001;
        #10000;
        sw = 3'b010;
        #10000;
        sw = 3'b011;
        #10000;
        sw = 3'b100;
        #10000;
        sw = 3'b101;
        #10000;
        sw = 3'b110;
        #10000;
        sw = 3'b111;
        #10000;

        $finish;
    end
endmodule
