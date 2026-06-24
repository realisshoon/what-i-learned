`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 15:10:27
// Design Name: 
// Module Name: tb_tick_gen
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


module tb_tick_gen();
    reg clk,rst;
    wire o_tick;

    clk_tick_gen dut(
        .clk(clk),
        .rst(rst),
        .o_tick(o_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        
        #20;
        rst = 0;


        // 200msec delay
        #200_000_000;
        $stop;

    end

endmodule
