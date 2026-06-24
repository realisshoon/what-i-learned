`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/14 14:17:29
// Design Name: 
// Module Name: set_det_mealy
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


module set_det_mealy (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    reg [2:0] state_reg, next_state;

    parameter start = 3'b000;
    parameter rd0_once = 3'b001;
    parameter rd1_once = 3'b010;
    parameter rd0_twice = 3'b011;
    parameter rd1_twice = 3'b100;

    always @(*) begin
        next_state = start;
        case (state_reg)
            start: begin
                if (din_bit == 0) begin
                    next_state = rd0_once;
                end else if (din_bit == 1) begin
                    next_state = rd1_once;
                end else
                next_state = start;
            end
            rd0_once: begin
                if (din_bit == 0) begin
                    next_state = rd0_twice;
                end else if (din_bit == 1) begin
                    next_state = rd1_once;
                end
            end
            rd1_once: begin
                if (din_bit == 0) begin
                    next_state = rd0_twice;
                end else if (din_bit == 1) begin
                    next_state = rd1_twice;
                end
            end
            rd0_twice: begin
                if (din_bit == 0) begin
                    next_state = rd0_twice;
                end else if (din_bit == 1) begin
                    next_state = rd1_twice;
                end
            end
            rd1_twice: begin
                if (din_bit == 0) begin
                    next_state = rd0_twice;
                end else if (din_bit == 1) begin
                    next_state = rd1_twice;
                end
            end
        endcase
    end

    // state reg 
    always @(posedge clk, posedge rst) begin
        if (rst == 1) state_reg <= start;
        else state_reg <= next_state;
    end

    // assign dout_bit =((state_reg==rd0_twice) && (din_bit == 0) || (state_reg==rd1_twice) && (din_bit ==1 )) ? 1 : 0;
    assign dout_bit = ((state_reg == rd0_twice) || (state_reg == rd1_twice)) ? 1 : 0;



endmodule
