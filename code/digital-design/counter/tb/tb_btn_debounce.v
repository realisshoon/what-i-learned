`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/15 15:39:29
// Design Name: 
// Module Name: tb_btn_debounce
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


module tb_btn_debounce();

reg clk,rst,i_btn;
wire o_btn;

button_debounce dut(
        .clk(clk),
        .rst(rst),
        .i_btn(i_btn),
        .o_btn(o_btn)
);

    always #5 clk = ~clk;


    initial begin
        clk = 0 ;
        rst = 1 ;
        i_btn = 0;

        repeat (3) @(negedge clk ); // ?

        rst = 0;
        #10;
        i_btn = 1;

        repeat (8000) @(negedge clk ); // 왜 10임

        i_btn = 0; 

        #20;
        $stop;

    end


endmodule



