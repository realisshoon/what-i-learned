`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 10:19:16
// Design Name: 
// Module Name: tb_adder_8bit
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


module tb_adder_8bit ();
    reg [7:0] a, b;
    wire [7:0] s;
    wire c;

    integer i, j;

    adder_8bit dut (
        .a  (a),
        .b  (b),
        .sum(s),
        .c  (c)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
    end

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #10;
            end
        end
        $finish;
    end
endmodule
