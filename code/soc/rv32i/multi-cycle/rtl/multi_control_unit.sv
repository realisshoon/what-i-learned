`timescale 1ns / 1ps
`include "define.vh"

module multi_control_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] mem_mode,
    output logic [ 2:0] rfsrc_sel,
    output logic        dwe,
    output logic        alu_src_sel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        pc_en
);

  // Debugging opcode enumeration
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

  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [6:0] opcode;

  assign funct3 = instr_code[14:12];
  assign funct7 = instr_code[31:25];
  assign opcode = instr_code[6:0];

  opcode_dbg_e opcode_dbg;
  assign opcode_dbg = opcode_dbg_e'(opcode);

  // FSM States
  typedef enum logic [3:0] {
    FETCH,
    DECODE,
    EXECUTE,
    MEM,
    WB
  } state_e;

  state_e c_state, n_state;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      c_state <= FETCH;
    end else begin
      c_state <= n_state;
    end
  end

  //state next
  always_comb begin
    n_state     = c_state;
    case (c_state)
      FETCH: begin
        n_state = DECODE;
      end

      DECODE: begin
        n_state = EXECUTE;
      end

      EXECUTE: begin
        case(opcode)
          `R_TYPE, `I_TYPE, `B_TYPE,`AU_TYPE,`J_TYPE,`JL_TYPE : begin
              n_state = FETCH;
          end
          `S_TYPE, `IL_TYPE : begin
            n_state = MEM;
          end
        endcase
        end
      MEM: begin
        if(opcode ==`S_TYPE) begin
            n_state = FETCH;
        end else begin
          n_state = WB;
        end
      end
      WB: begin
        n_state   = FETCH;
      end
    endcase
  end


//output
always_comb begin
    rf_we       = 1'b0;
    alu_control = 4'b0000;
    mem_mode    = 3'b000;
    rfsrc_sel   = 3'b000;
    dwe         = 1'b0;
    alu_src_sel = 1'b0;
    branch      = 1'b0;
    pc_en       = 1'b0;
    jal         = 1'b0;
    jalr        = 1'b0;
    case (c_state) 
    FETCH : pc_en = 1;
    EXECUTE : begin
      case(opcode) 
        `R_TYPE : begin
          rf_we = 1;
          alu_src_sel = 0;
          rfsrc_sel = 3'b000;
          alu_control = {funct7[5],funct3};
        end
        `I_TYPE : begin
          rf_we = 1;
          alu_src_sel = 1;
          rfsrc_sel = 3'b000;
          if(funct3 == 3'b101) alu_control= {funct7[5],funct3};
          else alu_control = {1'b0,funct3};
        end
        `B_TYPE : begin
          branch = 1;
          alu_src_sel=1'b0;
          alu_control={1'b0,funct3};
        end
        `J_TYPE, `JL_TYPE : begin
          rf_we = 1;
          jal = 1;
          if(opcode == `J_TYPE) begin
            jalr = 0;
          end else  begin
            jalr = 1;
          end
          rfsrc_sel = 3'b100;
        end
        `AU_TYPE , `LU_TYPE : begin
          rf_we= 1'b1;
          if(opcode == `LU_TYPE) rfsrc_sel = 3'b010;
          else rfsrc_sel = 3'b011;
        end
        `S_TYPE, `IL_TYPE: begin
            alu_src_sel = 1'b1;
            alu_control = `ADD;
        end
      endcase
    end
    MEM: begin
      //dwe, memory
      mem_mode = funct3;
      if(opcode == `S_TYPE) dwe = 1'b1;
      else dwe = 1'b0;
    end

    WB : begin
      rf_we = 1'b1;
      rfsrc_sel = 1'b1;
    end
    endcase
end
endmodule