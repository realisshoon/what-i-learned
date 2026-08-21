`timescale 1ns / 1ps

module top_rv32i_soc(
    input logic clk,
    input logic rst
    );
    
    logic [31:0] instr_addr, daddr,dwdata,drdata;
    logic [31:0] instr_code;
    logic [2:0] mem_mode;
    logic dwe;

    rv32i_cpu U_RV32I_CPU(
        .*
    );
    data_mem U_DATA_MEM(
        .*
    );

    instruction_mem U_INSTRUCTION_MEM(
        .*
    );
    
endmodule
