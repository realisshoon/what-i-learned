`timescale 1ns / 1ps

module tb_sr04_controller ();

    parameter US_DELAY = 1000;      // 1us 대기
    parameter MS_DELAY = 1_000_000; // 1ms 대기

    reg clk;
    reg rst;
    reg sr04_start;
    reg echo;
    wire trig;
    wire [8:0] distance;
    wire w_tick_us;

    integer i;
    integer rand_us;

    // 1us 틱 발생기
    tick_gen_us dut2 (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    // 초음파 컨트롤러
    sr04_controller dut (
        .clk(clk),
        .rst(rst),
        .sr04_start(sr04_start),
        .tick_us(w_tick_us),
        .echo(echo),
        .trig(trig),
        .distance(distance)
    );

    // 100MHz 클럭 생성
    always #5 clk = ~clk;

    initial begin
        // 1. 초기화
        clk = 0;
        rst = 1;
        sr04_start = 0;
        echo = 0;
        #100;
        rst = 0;
        #100;

        @(posedge clk);
        sr04_start = 1; 
        @(posedge clk);
        sr04_start = 0;

        #(US_DELAY * 20);
        
        echo = 1;
        #(MS_DELAY * 1);
        echo = 0;
        
        #1000; 


        for (i = 0; i < 5; i = i + 1) begin
            #50000; 
            
            rand_us = $urandom_range(116, 23200);
            
            @(posedge clk);
            sr04_start = 1;  
            @(posedge clk);
            sr04_start = 0;

            #(US_DELAY * 20);
            
            echo = 1;
            #(US_DELAY * rand_us);
            echo = 0;

            #2000;
            
            $display("[Random Test %0d] Echo delay: %0d us -> Expected Distance: %0d cm", i+1, rand_us, rand_us/58);
        end

        $stop;
    end

endmodule
