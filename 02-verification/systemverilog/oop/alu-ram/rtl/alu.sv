`timescale 1ns / 1ps

module alu(
    input logic       opcode,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] result
    );

    always_comb begin
        case(opcode)
            1'b0 : result = a+b;
            1'b1 : result = a-b;
            default : result = 8'b0;
        endcase
    end
    
endmodule
