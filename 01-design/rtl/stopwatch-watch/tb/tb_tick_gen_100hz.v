`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/16 10:43:46
// Design Name: 
// Module Name: tb_tick_gen_100hz
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


module tb_tick_gen_100hz();
    reg clk, rst;
    wire o_tick_100hz;

    tick_gen_100hz dut (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(o_tick_100hz)
    );        
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        rst = 0;

        repeat (1_100_000) @(posedge clk);

        $stop;

    end
    
endmodule
