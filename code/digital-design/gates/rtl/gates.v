`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/06 10:56:52
// Design Name: 
// Module Name: gates
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


module gates( //top module
    input a, 
    input b,
    output y0, // and
    output y1, // nand
    output y2, // or
    output y3, // nor
    output y4, // xor
    output y5, // xnor
    output y6  // not
    );

    assign y0 = a & b;
    assign y1 = ~(a & b);   
    assign y2 = a | b;      // | : vertical bar
    assign y3 = ~(a | b);
    assign y4 = a ^ b;      // ^ : caret
    assign y5 = ~(a ^ b);
    assign y6 = ~a;


endmodule