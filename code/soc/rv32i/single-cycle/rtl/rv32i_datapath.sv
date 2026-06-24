`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        pc_en,
    input  logic        jal,
    input  logic        jalr,
    input  logic        alu_src_sel,
    input  logic [ 2:0] rfsrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic [31:0] rs1, rs2, alu_result, alu_rs2_mux, wb_out, pc_imm, pc_4;
    logic [31:0] imm_extend;
    logic b_taken;

    assign daddr  = alu_result;
    assign dwdata = rs2;


    // mux2to1 U_REG_FILE_SRC_MUX (
    //     .in0(alu_result),
    //     .in1(drdata),
    //     .sel(rfsrc_sel),
    //     .out_mux(rfsrc_mux_out)
    // );


    mux_wb U_WB_MUX (
        .in0   (alu_result),
        .in1   (drdata),
        .in2   (imm_extend),
        .in3   (pc_imm),      //pc+imm
        .in4   (pc_4),
        .sel   (rfsrc_sel),
        .wb_out(wb_out)
    );

    reg_file U_REG_FILE (
        .clk   (clk),
        .rf_we (rf_we),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .waddr (instr_code[11:7]),
        .wdata (wb_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    mux2to1 U_MUX_ALU (
        .in0    (rs2),
        .in1    (imm_extend),
        .sel    (alu_src_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );


    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1),
        .rs2        (alu_rs2_mux),
        .alu_result (alu_result),
        .b_taken    (b_taken)
    );



    program_counter U_PC (
        .clk       (clk),
        .rst       (rst),
        .branch    (branch),
        .b_taken   (b_taken),
        .pc_en     (pc_en),
        .jal       (jal),
        .jalr      (jalr),
        .rs1       (rs1),
        .pc_in     (instr_addr),
        .pc_imm    (pc_imm),
        .imm_extend(imm_extend),
        .pc_out    (instr_addr),
        .pc_4      (pc_4)
    );

endmodule


module program_counter (
    input  logic        clk,
    input  logic        rst,
    input  logic        branch,
    input  logic        b_taken,
    input  logic        jal,
    input  logic        jalr,
    input  logic        pc_en,
    input  logic [31:0] rs1,
    input  logic [31:0] pc_in,
    input  logic [31:0] imm_extend,
    output logic [31:0] pc_imm,
    output logic [31:0] pc_4,
    output logic [31:0] pc_out

);

    logic [31:0] pc_reg, pc_next, pc_jalr;

    assign pc_out = pc_reg;
    assign pc_imm = (jalr) ? ((imm_extend + pc_jalr) & 32'hFFFF_FFFE) : (imm_extend + pc_jalr);
    assign pc_4   = pc_in + 32'd4;

    mux2to1 U_PC_JALR_MUX (
        .in0(pc_in),
        .in1(rs1),
        .sel(jalr),
        .out_mux(pc_jalr)
    );

    mux2to1 U_PC_SRC_MUX (
        .in0(pc_4),
        .in1(pc_imm),
        .sel(jalr | jal | (branch & b_taken)),
        .out_mux(pc_next)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else if (pc_en) begin
            pc_reg <= pc_next;
        end
    end


endmodule : program_counter


module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] sum
);

    assign sum = a + b;

endmodule : adder


module mux2to1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] out_mux
);
    assign out_mux = (sel) ? in1 : in0;

endmodule : mux2to1

module mux_wb (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] wb_out
);


    always_comb begin
        wb_out = 32'd0;
        case (sel)
            3'b000: wb_out = in0;  //load alu
            3'b001: wb_out = in1;  // load data mem
            3'b010: wb_out = in2;  // load LUI : Load upper imm
            3'b011: wb_out = in3;  // load Add Upper Imm to PC
            3'b100: wb_out = in4;  // load JAL/JALR : PC+4
        endcase
    end
endmodule : mux_wb


module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);
    always_comb begin
        imm_extend = 0;
        case (instr_code[6:0])
            `S_TYPE: imm_extend = {{20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]};
            `IL_TYPE, `I_TYPE, `JL_TYPE: imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            `LU_TYPE, `AU_TYPE: imm_extend = {instr_code[31:12], 12'h000};
            `B_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[7], instr_code[30:25], instr_code[11:8], 1'b0
            };
            `J_TYPE:
            imm_extend = {
                {12{instr_code[31]}}, instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0
            };
        endcase
    end

endmodule

module alu (
    input  logic [ 3:0] alu_control,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    output logic [31:0] alu_result,
    output logic        b_taken
);


    always_comb begin
        alu_result = 0;
        case (alu_control)
            // R-Type RD = RS1 + RS2
            // I-Type RD = RS1 + Imm(RS2)
            `ADD:  alu_result = rs1 + rs2;
            `SUB:  alu_result = rs1 - rs2;
            `SLL:  alu_result = rs1 << rs2[4:0];
            `SLT:  alu_result = ($signed(rs1) < $signed(rs2)) ? 1 : 0;
            `SLTU: alu_result = (rs1 < rs2) ? 1 : 0;
            `XOR:  alu_result = rs1 ^ rs2;
            `SRL:  alu_result = rs1 >> rs2[4:0];
            `SRA:  alu_result = $signed(rs1) >>> rs2[4:0];
            `OR:   alu_result = rs1 | rs2;
            `AND:  alu_result = rs1 & rs2;
        endcase
    end

    always_comb begin
        b_taken = 0;
        case (alu_control[2:0])
            `BEQ:  b_taken = (rs1 == rs2) ? 1'b1 : 1'b0;
            `BNE:  b_taken = (rs1 != rs2) ? 1'b1 : 1'b0;
            `BLT:  b_taken = ($signed(rs1) < $signed(rs2)) ? 1'b1 : 1'b0;
            `BGE:  b_taken = ($signed(rs1) >= $signed(rs2)) ? 1'b1 : 1'b0;
            `BLTU: b_taken = (rs1 < rs2) ? 1'b1 : 1'b0;
            `BGEU: b_taken = (rs1 >= rs2) ? 1'b1 : 1'b0;
        endcase
    end


endmodule : alu

module reg_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,
    input  logic [ 4:0] raddr2,
    input  logic        rf_we,
    input  logic [ 4:0] waddr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);

    logic [31:0] register_file[1:31];

`ifdef TEST_SIMULATION
    int i = 0;
    initial begin
        for (i = 1; i < 32; i++) register_file[i] = i;
    end
`endif


    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1) ? register_file[raddr1] : 32'h0000_0000;  // addr = 0 : fixed 0
    assign rdata2 = (raddr2) ? register_file[raddr2] : 32'h0000_0000;  // addr = 0 : fixed 0

endmodule : reg_file



