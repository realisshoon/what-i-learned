`timescale 1ns / 1ps
// Top module

module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic[31:0] drdata,
    input  logic [31:0] instr_code,
    output logic [31:0] instr_addr,
    output logic [2:0] mem_mode,
    output logic        dwe,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic rf_we, alu_src_sel, branch;
    logic [2:0] rfsrc_sel;
    logic [3:0] alu_control;
    logic jal, jalr;
    


    control_unit U_CONTROL_UNIT(.*);
    datapath U_DATAPATH(.*);



endmodule




// // control unit

// module control_unit();
// endmodule

// // datapath

// module datapath();
// endmodule
