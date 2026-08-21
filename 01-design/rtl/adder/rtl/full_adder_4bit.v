`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/07 11:39:57
// Design Name: 
// Module Name: full_adder_4bit
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
    input [3:0] a,
    b,
    input cin,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output led
);

    wire [3:0] w_sum;


    fnd_controller U_FND_CNTL (
        .bin(w_sum),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


    full_adder_4bit U_FA4 (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(w_sum),
        .cout(led)
    );

endmodule


module full_adder_4bit (
    input [3:0] a,
    b,
    input cin,
    output [3:0] sum,
    output cout
);

    wire c1, c2, c3;

    full_adder FA0 (
        .a  (a[0]),
        .b  (b[0]),
        .cin(cin),
        .s  (sum[0]),
        .c  (c1)
    );

    full_adder FA1 (
        .a  (a[1]),
        .b  (b[1]),
        .cin(c1),
        .s  (sum[1]),
        .c  (c2)
    );
    full_adder FA2 (
        .a  (a[2]),
        .b  (b[2]),
        .cin(c2),
        .s  (sum[2]),
        .c  (c3)
    );
    full_adder FA3 (
        .a  (a[3]),
        .b  (b[3]),
        .cin(c3),
        .s  (sum[3]),
        .c  (cout)
    );
endmodule

// 아래부터는 외부 파일(adder.v)을 쓰지 않고 이 파일 하나에서
// 모두 해결하기 위해 추가한 full_adder와 half_adder 모듈입니다.

module full_adder (
    input  a,
    b,
    cin,
    output s,
    c
);

    wire s1, c1, c2;
    assign c = c1 | c2;

    half_adder U_HA0 (
        .a(a),
        .b(b),
        .s(s1),
        .c(c1)
    );

    half_adder U_HA1 (
        .a(s1),
        .b(cin),
        .s(s),
        .c(c2)
    );

endmodule

module half_adder (
    input  a,
    b,
    output s,
    c
);
    assign s = a ^ b;
    assign c = a & b;

endmodule
