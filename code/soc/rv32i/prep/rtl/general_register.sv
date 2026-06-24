`timescale 1ns / 1ps

module general_register(
    input clk,
    input rst,
    output [7:0] out
    );
endmodule




module reg_file(
    input logic clk,
    input logic rst,
    input logic [7:0] wd,
    input logic [1:0] ra0,
    input logic [1:0] ra1,
    input logic [1:0] wa,
    input logic       we,
    output logic [7:0] rd0,
    output logic [7:0] rd1
    );

    logic [7:0] register [0:3];


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register[0] <= 8'd0;
            register[1] <= 8'd0;
            register[2] <= 8'd0;
            register[3] <= 8'd0;
        end else if(we) begin
            if (wa!= 2'b00) begin
                register[wa] <= wd;
            end
        end
    end

    always_comb begin
        case (ra0)
            2'b00 : rd0 = 8'b0;
            2'b01 : rd0 = register[1];
            2'b10 : rd0 = register[2];
            2'b11 : rd0 = register[3];
        endcase

        case (ra1)
            2'b00 : rd1 = 8'b0;
            2'b01 : rd1 = register[1];
            2'b10 : rd1 = register[2];
            2'b11 : rd1 = register[3];
        endcase

    end

endmodule


module control_unit(
    input logic clk,
    input logic rst,
    input logic 
);
endmodule

module alu_unit(
    input [7:0] a,
    input [7:0] b,
    output logic [7:0] alu_out
    );

    assign alu_out = a + b;

endmodule