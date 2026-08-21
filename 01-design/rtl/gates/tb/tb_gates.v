`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/06 14:25:07
// Design Name: 
// Module Name: tb_gates
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

// test  simulation environment module


module tb_gates ();

    reg a, b;
    wire y0, y1, y2, y3, y4, y5, y6;


    gates dut (
        .a (a),
        .b (b),
        .y0(y0),  // and
        .y1(y1),  // nand
        .y2(y2),  // or
        .y3(y3),  // nor
        .y4(y4),  // xor
        .y5(y5),  // xnor
        .y6(y6)   // not
    );

    initial begin
        a = 0;
        b = 0;
        #10;  // 01 번째 줄에 timeslot ns 로 지정 해놓음 
        a = 0;
        b = 1;
        #10;
        a = 1;
        b = 0;
        #10;
        a = 1;
        b = 1;
        #10;
        $finish;
    end

endmodule
