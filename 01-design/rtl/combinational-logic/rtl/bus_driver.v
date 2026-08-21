`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/15 10:15:16
// Design Name: 
// Module Name: bus_driver
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


module bus_driver(
    input [7:0] data_a,
    input [7:0] data_b,
    input en_a,
    input en_b,
    output [7:0] bus_data
    );

    assign bus_data = en_a ? data_a : en_b ? data_b : 8'hzz;

    bufif1 bf1 [7:0] (bus_data,data_a,en_a);
    bufif1 bf2 [7:0] (bus_data,data_b,en_b);



endmodule
