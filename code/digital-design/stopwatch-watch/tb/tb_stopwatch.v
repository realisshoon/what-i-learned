`timescale 1ns / 1ps

module tb_stopwatch();

    reg clk;
    reg rst;
    reg i_clear;
    reg i_mode;
    reg i_run_stop;

    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;



    stopwatch_datapath dut (
                .clk            (clk),
                .rst            (rst),
                .i_run_stop     (i_run_stop),
                .i_clear        (i_clear),
                .i_mode         (i_mode),
                .msec           (msec),
                .sec            (sec),
                .min            (min),
                .hour           (hour)
    );

    always #5 clk = ~clk; 

    initial begin
        clk             = 0; 
        rst             = 1;
        i_clear         = 0;
        i_mode          = 0;
        i_run_stop      = 0;

        #20 rst = 0;

        // ==========================================
        // 시나리오 1: 스톱워치 RUN (정상 카운트)
        // ==========================================
        $display("--- Scenario 1: Stopwatch RUN ---");
        #10 i_run_stop = 1; 

        #1000; 

        // ==========================================
        // 시나리오 2: 스톱워치 STOP (시간 정지)
        // ==========================================
        $display("--- Scenario 2: Stopwatch STOP ---");
        i_run_stop = 0;
        

        #500; 

        // ==========================================
        // 시나리오 3: 스톱워치 재개 후 CLEAR (리셋)
        // ==========================================
        $display("--- Scenario 3: Stopwatch Resume & CLEAR ---");
        i_run_stop = 1;
        #500;
        
        i_clear = 1;   
        #20 i_clear = 0;
        

        #200;

        $finish;
    end

endmodule