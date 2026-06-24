`timescale 1ns / 1ps


module tb_sr04();

    reg         clk;
    reg         rst;
    reg         sr04_start;
    reg         echo;
    wire        trig;
    wire [12:0] data;

    sr04_datapath dut(
        .clk(clk),
        .rst(rst),
        .sr04_start(sr04_start),
        .echo(echo),
        .trig(trig),
        .data(data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sr04_start = 0;
        echo = 0;
        #20
        rst = 0;
        @(negedge clk);

        sr04_start = 1;
        #10;
        sr04_start = 0; 

        #20_000; 


        echo = 1;

        #23_300_000; //400 us 이상  
        echo = 0;


        #20_000;
        $finish;
    end

endmodule