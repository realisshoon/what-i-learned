`timescale 1ns / 1ps

module tb_input_controller ();

    reg clk;
    reg rst;
    reg sw2_enable;
    reg btnR, btnL, btnD, btnU;

    wire wt_btnR, wt_btnL, wt_btnD, wt_btnU;
    wire sw_btnR, sw_btnL, sw_btnD, sw_btnU;


    input_controller dut (
        .clk(clk),
        .rst(rst),
        .sw2_enable(sw2_enable),
        .btnR(btnR),
        .btnL(btnL),
        .btnD(btnD),
        .btnU(btnU),
        .wt_btnR(wt_btnR),
        .wt_btnL(wt_btnL),
        .wt_btnD(wt_btnD),
        .wt_btnU(wt_btnU),
        .sw_btnR(sw_btnR),
        .sw_btnL(sw_btnL),
        .sw_btnD(sw_btnD),
        .sw_btnU(sw_btnU)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sw2_enable = 0;
        {btnR, btnL, btnD, btnU} = 4'b0000;

        #20 rst = 0;
        #200;
    end

    initial begin
        #200;
        btnR = 1;
        #10;
        btnR = 0;
        #10;
        btnR = 1;
        #10;
        btnR = 0;
        #10;
        btnR = 1;


        #500;

        btnR = 0;
        #100;

        sw2_enable = 1;
        
        #523 
        btnR = 1; 

        #557 // 떨어질 때도 메인 클럭에 맞지 않게 설정
        btnR = 0;

        // 짧은 글리치(Glitch) 테스트 (클럭보다 짧은 잡음)
        #12
        btnR = 1;
        #3
        btnR = 0;

        #300;
        $finish;
    end


endmodule
