`timescale 1ns / 1ps

module tb_stopwatch_datapath ();

    parameter SEC_DELAY = 1_000_000;
    parameter MIN_DELAY = 60_000_000;


    reg clk, rst , i_run_stop, i_clear, i_mode;
    wire [6:0] msec;
    wire [5:0] sec, min;
    wire [4:0] hour;


    stopwatch_datapath dut (
        .clk (clk),
        .rst (rst),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_run_stop(i_run_stop),
        .msec(msec),
        .sec (sec),
        .min (min),
        .hour(hour)
    );

    // 시뮬레이션 속도를 극적으로 높이기 위해 100Hz 틱 발생기의 카운트 값을 1로 최소화합니다.
    // 매 클럭(clock)마다 1 msec씩 올라가게 됩니다.
    defparam dut.U_TICK_GEN_100HZ.F_COUNT = 1;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        i_run_stop = 1'b0;
        i_clear = 1'b0;
        i_mode = 1'b0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        i_run_stop = 1;
        repeat (10) #(SEC_DELAY);
        i_clear = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        i_clear = 0;
        #(SEC_DELAY);


        i_clear = 1;
        #(MIN_DELAY);



        // // F_COUNT가 1일 때, 1시간이 지나기 위한 클럭 수는 다음과 같습니다:
        // // 1sec = 100 tick
        // // 1min = 60 sec = 6,000 tick
        // // 1hour = 60 min = 360,000 tick
        // // 따라서 400,000번 정도 반복하면 방금 돌린 것보다 훨씬 빨리(거의 즉시) 1시간(hour)이 올라가는 것을 확인할 수 있습니다.
        
        // repeat (400_000) @(negedge clk); 
        $stop;


    end


endmodule
