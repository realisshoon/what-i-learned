`timescale 1ns / 1ps

module top_rv32i_soc (
    input logic clk,
    input logic rst
);

  // ROM Signals
  logic [31:0] instr_addr;
  logic [31:0] instr_code;

  // CPU <-> APB Master Signals
  logic [31:0] Addr;
  logic [31:0] WDATA;
  logic [31:0] RDATA;
  logic        W_REQ;
  logic        R_REQ;
  logic        READY;
  logic [ 2:0] mem_mode;

  // APB Master <-> Slaves Signals
  logic [31:0] PADDR;
  logic [31:0] PWDATA;
  logic        PENABLE;
  logic        PWRITE;
  logic        PSEL0;
  logic        PSEL1;
  logic        PSEL2;
  logic        PSEL3;
  logic        PSEL4;
  logic        PREADY0;
  logic        PREADY1;
  logic        PREADY2;
  logic        PREADY3;
  logic        PREADY4;
  logic [31:0] PRDATA0;
  logic [31:0] PRDATA1;
  logic [31:0] PRDATA2;
  logic [31:0] PRDATA3;
  logic [31:0] PRDATA4;

  // ROM Instantiation
  rom U_ROM (
      .instr_addr(instr_addr),
      .instr_code(instr_code)
  );

  // CPU Instantiation
  rv32i_cpu U_CPU (
      .clk       (clk),
      .rst       (rst),
      .instr_code(instr_code),
      .instr_addr(instr_addr),
      .Addr      (Addr),
      .WDATA     (WDATA),
      .RDATA     (RDATA),
      .W_REQ     (W_REQ),
      .R_REQ     (R_REQ),
      .READY     (READY),
      .mem_mode  (mem_mode)
  );

  // Direct RAM Instantiation
  ram U_RAM (
      .clk     (clk),
      .R_REQ     (R_REQ),
      .W_REQ     (W_REQ),
      .mem_mode(mem_mode),
      .Addr   (Addr),
      .WDATA  (WDATA),
      .RDATA  (RDATA)
  );

  // APB Master Instantiation
  APB_Master U_APB_MASTER (
      .PCLK   (clk),
      .PRESET (rst),
      .Addr   (Addr),
      .WDATA  (WDATA),
      .RDATA  (RDATA),
      .W_REQ  (W_REQ),
      .R_REQ  (R_REQ),
      .READY  (READY),
      .PADDR  (PADDR),
      .PWDATA (PWDATA),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),
      .PSEL0  (PSEL0),
      .PSEL1  (PSEL1),
      .PSEL2  (PSEL2),
      .PSEL3  (PSEL3),
      .PSEL4  (PSEL4),
      .PREADY0(PREADY0),
      .PREADY1(PREADY1),
      .PREADY2(PREADY2),
      .PREADY3(PREADY3),
      .PREADY4(PREADY4),
      .PRDATA0(PRDATA0),
      .PRDATA1(PRDATA1),
      .PRDATA2(PRDATA2),
      .PRDATA3(PRDATA3),
      .PRDATA4(PRDATA4)
  );

  // APB Slave 0: BRAM Instantiation
  APB_BRAM U_APB_BRAM (
      .PCLK   (clk),
      .PRESET (rst),
      .PADDR  (PADDR),
      .PWDATA (PWDATA),
      .PSEL   (PSEL0),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),
      .PREADY (PREADY0),
      .PRDATA (PRDATA0)
  );

  // Unused APB Slaves Default Ties to prevent simulation hangs / undefined read states
  assign PREADY1 = 1'b1;
  assign PRDATA1 = 32'd0;

  assign PREADY2 = 1'b1;
  assign PRDATA2 = 32'd0;

  assign PREADY3 = 1'b1;
  assign PRDATA3 = 32'd0;

  assign PREADY4 = 1'b1;
  assign PRDATA4 = 32'd0;

endmodule
