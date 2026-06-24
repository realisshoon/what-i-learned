`timescale 1ns / 1ps
`include "define.vh"

module control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] mem_mode,
    output logic [ 2:0] rfsrc_sel,
    output logic        dwe,
    output logic        alu_src_sel,
    output logic        branch,
    output logic        jal,
    output logic        jalr
);

  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [6:0] opcode;

  assign funct3 = instr_code[14:12];
  assign funct7 = instr_code[31:25];
  assign opcode = instr_code[6:0];


  //[debug]
  typedef enum logic [6:0] {
    DBG_R_TYPE  = `R_TYPE,
    DBG_S_TYPE  = `S_TYPE,
    DBG_I_TYPE  = `I_TYPE,
    DBG_IL_TYPE = `IL_TYPE,
    DBG_B_TYPE  = `B_TYPE,
    DBG_LU_TYPE = `LU_TYPE,
    DBG_AU_TYPE = `AU_TYPE,
    DBG_J_TYPE  = `J_TYPE,
    DBG_JL_TYPE = `JL_TYPE
  } opcode_dbg_e;

  opcode_dbg_e opcode_dbg;
  assign opcode_dbg = opcode_dbg_e'(opcode);

  always_comb begin
    rf_we       = 0;
    jal         = 0;
    jalr        = 0;
    alu_src_sel = 0;
    alu_control = 4'b0;
    rfsrc_sel   = 3'b0;
    mem_mode    = 3'b0;
    branch      = 0;
    dwe         = 0;
    case (opcode)
      `R_TYPE: begin
        rf_we       = 1;
        jal         = 0;
        jalr        = 0;
        rfsrc_sel   = 3'b000;
        alu_src_sel = 0;
        alu_control = {funct7[5], funct3};
        mem_mode    = 3'b0;
        branch      = 0;
        dwe         = 0;
      end
      `S_TYPE: begin
        rf_we       = 0;
        jal         = 0;
        jalr        = 0;
        rfsrc_sel   = 3'b000;
        alu_src_sel = 1;
        alu_control = `ADD;
        mem_mode    = funct3;
        branch      = 0;
        dwe         = 1;
      end
      `IL_TYPE: begin
        rf_we       = 1;
        jal         = 0;
        jalr        = 0;
        rfsrc_sel   = 3'b001;  // store result from memory
        alu_src_sel = 1;
        alu_control = `ADD;
        mem_mode    = funct3;
        branch      = 0;
        dwe         = 0;
      end
      `I_TYPE: begin
        rf_we       = 1;
        jal         = 0;
        jalr        = 0;
        rfsrc_sel   = 3'b000;
        alu_src_sel = 1;
        if (funct3 == 3'b101) begin
          alu_control = {funct7[5], funct3};
        end else begin
          alu_control = {1'b0, funct3}; 
        end
        mem_mode    = 3'b0;
        branch      = 0;
        dwe         = 0;
      end
      `B_TYPE: begin
        rf_we       = 0;
        jal         = 0;
        jalr        = 0;
        rfsrc_sel   = 3'b000;
        alu_src_sel = 0; 
        alu_control = {1'b0, funct3};
        mem_mode    = 3'b0;
        branch      = 1;
        dwe         = 0;
      end
      `LU_TYPE, `AU_TYPE: begin
        rf_we       = 1;
        jal         = 0;
        jalr        = 0;
        if (opcode == `LU_TYPE) begin 
          rfsrc_sel = 3'b010;
        end else begin
          rfsrc_sel = 3'b011;
        end
        alu_src_sel = 0;
        alu_control = 4'b0;
        mem_mode    = 3'b0;
        branch      = 0;
        dwe         = 0;
      end
      `J_TYPE, `JL_TYPE: begin
        rf_we = 1;
        if (opcode == `J_TYPE) begin
          jal  = 1;
          jalr = 0;
        end else begin
          jal  = 1;
          jalr = 1;
        end
        rfsrc_sel   = 3'b100; // PC + 4
        alu_src_sel = 0;
        alu_control = 4'b0;
        mem_mode    = 3'b0;
        branch      = 0;
        dwe         = 0;
      end
    endcase
  end

endmodule : control_unit


// always_comb begin
//     rf_we = 0;
//     alu_control = 0;
//     case (opcode)
//         `R_TYPE: begin
//             rf_we = 1;
//             case ({
//                 funct7[5], funct3
//                 })
//                 `ADD: alu_control = `ADD;
//                 `SUB: alu_control = `SUB;
//                 `SLT: alu_control = `SLT;
//                 `OR:  alu_control = `OR;
//                 `AND: alu_control = `AND;
//                 `SLL: alu_control = `SLL;
//                 `SRL: alu_control = `SRL;
//                 `SRA: alu_control = `SRA;
//                 `XOR: alu_control = `XOR;
//                 `SLTU: alu_control = `SLTU;
//             endcase
//         end
//     endcase
// end
