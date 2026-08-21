`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/07 10:47:57
// Design Name: 
// Module Name: tb_adder
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


module tb_adder();

reg a, b, cin;
wire s, c;

// instanciation
// dut : design under test
// uut : unit under test
full_adder dut(
    .a(a) ,
    .b(b) ,
    .cin(cin) ,
    .s (s),
    .c (c)
);


initial begin

    // int, time control
    a=0;
    b=0;
    cin=0;

    #10;

    a=0;
    b=1;
    cin=0;

    #10;

    a=1;
    b=0;
    cin=0;

    #10;
    
    a=1;
    b=1;
    cin=0;

    #10;


    a=0;
    b=0;
    cin=1;

    #10;

    a=0;
    b=1;
    cin=1;

    #10;

    a=1;
    b=0;
    cin=1;

    #10;
    
    a=1;
    b=1;
    cin=1;

    #10;

    $stop;

    end
endmodule

