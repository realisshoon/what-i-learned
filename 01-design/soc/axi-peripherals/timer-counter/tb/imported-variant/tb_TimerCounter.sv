`timescale 1ns / 1ps

module tb_TimerCounter ();

    logic        clk;
    logic        rst_n;
    logic        cnt_en;
    logic        intr_en;
    logic [31:0] psc;
    logic [31:0] arr;
    logic [31:0] o_cnt;
    logic        intr;
    logic        cnt_valid;
    logic [31:0] i_cnt;


    TimerCounter dut (.*);


    task automatic TIM_SetPSC(logic [31:0] prescale);
        psc = prescale;
    endtask

    task automatic TIM_SetARR(logic [31:0] autoReload);
        arr = autoReload;
    endtask  //automatic

    task automatic TIM_EnTimer();
        cnt_en = 1'b1;
    endtask  //automatic

    task automatic TIM_DisTimer();
        cnt_en = 1'b0;
    endtask  //automatic

    task automatic TIM_EnIntr();
        intr_en = 1'b1;
    endtask  //automatic

    task automatic TIM_DisIntr();
        intr_en = 1'b0;
    endtask  //automatic

    task automatic TIM_SetCNT(logic [31:0] CNT);
        i_cnt     <= CNT;
        cnt_valid <= 1'b1;
        @(posedge clk);
        cnt_valid <= 1'b0;
    endtask  //automatic


    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        rst_n = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        TIM_SetPSC(100 - 1);  // output 1MHz
        TIM_SetARR(1000 - 1);  // TimerCounter 0 ~ 999
        TIM_EnTimer();
        TIM_DisIntr();


        wait (o_cnt == 999);
        @(posedge clk);
        wait (o_cnt == 0);
        @(posedge clk);
        TIM_EnIntr();
        wait (o_cnt == 999);
        @(posedge clk);
        wait (o_cnt == 100);
        TIM_SetCNT(10);
        @(posedge clk);
        wait (o_cnt == 0);
        TIM_DisTimer();


        #1000;
        $finish;
    end


endmodule
