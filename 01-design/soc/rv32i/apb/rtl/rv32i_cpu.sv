`timescale 1ns / 1ps

module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    output logic [31:0] instr_addr,

    // CPU to APB Master interface
    output logic [31:0] Addr,
    output logic [31:0] WDATA,
    input  logic [31:0] RDATA,
    output logic        W_REQ,
    output logic        R_REQ,
    input  logic        READY,
    output logic [ 2:0] mem_mode
);

  logic rf_we, alu_src_sel, branch;
  logic [2:0] rfsrc_sel;
  logic [3:0] alu_control;
  logic jal, jalr;
  logic pc_en;

  control_unit U_CONTROL_UNIT (
      .*
  );

  datapath U_DATAPATH (
    .*
  );

endmodule

