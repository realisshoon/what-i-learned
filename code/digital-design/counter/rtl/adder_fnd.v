`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SAMSUNG
// Engineer: SEUNG_HOON HAN
// 
// Create Date: 2026/04/08 09:43:01
// Design Name: 
// Module Name: adder
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


module adder_fnd (
    input clk,
    input rst,
    input [7:0] a,b,

    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output led
);

    wire [7:0] w_sum;


    fnd_controller U_FND_CNTL (
        .clk (clk),
        .rst (rst),
        .fnd_in(w_sum),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


    adder_8bit U_ADDER_8BIT (
        .a(a),
        .b(b),
        .sum(w_sum),
        .c(led)
    );

endmodule


// 3. 4-bit Full Adder 2개를 연결한 8-bit Full Adder
module adder_8bit(
    input [7:0] a, b,
    output [7:0] sum,
    output c
);
    wire w_c; // 하위 4비트의 Carry를 상위 4비트로 전달할 선
    
    // 하위 4비트 계산 (비트 0 ~ 3)
    full_adder_4bit FA4_LOWER (
        .a(a[3:0]), 
        .b(b[3:0]), 
        .cin(1'b0), 
        .sum(sum[3:0]), 
        .cout(w_c)
    );
    
    // 상위 4비트 계산 (비트 4 ~ 7)
    full_adder_4bit FA4_UPPER (
        .a(a[7:4]), 
        .b(b[7:4]), 
        .cin(w_c), // 하위에서 올라온 캐리를 입력으로 받음
        .sum(sum[7:4]), 
        .cout(c)
    );
endmodule


// 2. 1-bit Full Adder 4개를 연결한 4-bit Full Adder
module full_adder_4bit(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire c1, c2, c3; // 내부 캐리를 연결할 선

    full_adder_1bit FA0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c1));
    full_adder_1bit FA1 (.a(a[1]), .b(b[1]), .cin(c1),  .sum(sum[1]), .cout(c2));
    full_adder_1bit FA2 (.a(a[2]), .b(b[2]), .cin(c2),  .sum(sum[2]), .cout(c3));
    full_adder_1bit FA3 (.a(a[3]), .b(b[3]), .cin(c3),  .sum(sum[3]), .cout(cout));
endmodule

// 1. 가장 기본 단위인 1-bit Full Adder
module full_adder_1bit(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (cin & a);
endmodule






