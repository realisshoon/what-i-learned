`timescale 1ns / 1ps

module tb_TimerCounter ();

    logic        clk;
    logic        rst_n;
    logic        cnt_en;
    logic        intr_en;
    logic [31:0] psc;
    logic [31:0] arr;
    logic [31:0] cnt;
    logic        intr;

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


        wait (cnt == 999);
        @(posedge clk);

        wait (cnt == 999);
        @(posedge clk);


        #1000;
        $finish;
    end


endmodule
