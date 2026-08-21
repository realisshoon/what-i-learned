`timescale 1ns / 1ps


`define TEST_SIMULATION 

module rom(
        input logic [31:0] instr_addr,
        output logic [31:0] instr_code
    );

        logic [31:0] instr_rom[0:255];

        initial begin
            // --- [1] 기본 레지스터 초기값 적재 (I-type ADDI) ---
            instr_rom[0] = 32'h00f00093; // [PC 0x00] addi x1, x0, 15    ; x1 = 15
            instr_rom[1] = 32'hff600113; // [PC 0x04] addi x2, x0, -10   ; x2 = -10 (0xFFFFFFF6) - 부호확장 검증용 음수 설정

            // --- 덧셈 비교 (R-type ADD vs I-type ADDI) ---
            instr_rom[2] = 32'h002081b3; // [PC 0x08] add  x3, x1, x2    ; x3 = x1 + x2 = 5  (R-Type)
            instr_rom[3] = 32'h00508213; // [PC 0x0C] addi x4, x1, 5     ; x4 = x1 + 5 = 20  (I-Type)

            // --- 뺄셈 연산 (R-type SUB) ---
            instr_rom[4] = 32'h402082b3; // [PC 0x10] sub  x5, x1, x2    ; x5 = x1 - x2 = 25 (R-Type)

            // --- 왼쪽 시프트 비교 (R-type SLL vs I-type SLLI) ---
            instr_rom[5] = 32'h00209313; // [PC 0x14] slli x6, x1, 2     ; x6 = x1 << 2 = 60 (I-Type)
            instr_rom[6] = 32'h002093b3; // [PC 0x18] sll  x7, x1, x2    ; x7 = x1 << x2[4:0] (x2의 하위 5비트는 22이므로 x1 << 22)

            // --- 논리 AND 비교 (R-type AND vs I-type ANDI) ---
            instr_rom[7] = 32'h0020f433; // [PC 0x1C] and  x8, x1, x2    ; x8 = x1 & x2
            instr_rom[8] = 32'h00a0f493; // [PC 0x20] andi x9, x1, 10    ; x9 = x1 & 10

            // --- 메모리 저장 (S-type SW / SH / SB) ---
            instr_rom[9]  = 32'h00102223; // [PC 0x24] sw   x1, 4(x0)     ; Store Word: Mem[4] = x1 (15)  (S-Type)
            instr_rom[10] = 32'h00201423; // [PC 0x28] sh   x2, 8(x0)     ; Store Half: Mem[8] = x2의 하위 16비트(0xFFF6)  (S-Type)
            instr_rom[11] = 32'h002005a3; // [PC 0x2C] sb   x2, 11(x0)    ; Store Byte: Mem[11] = x2의 하위 8비트(0xF6)   (S-Type)

            // --- 조건 분기 (B-type BEQ / BNE) ---
            instr_rom[12] = 32'h00108463; // [PC 0x30] beq  x1, x1, 8     ; Taken (BEQ)
            instr_rom[13] = 32'h06300513; // [PC 0x34] addi x10, x0, 99   ; Skipped
            instr_rom[14] = 32'h00109463; // [PC 0x38] bne  x1, x1, 8     ; Not Taken (BNE)
            instr_rom[15] = 32'h00f00513; // [PC 0x3C] addi x10, x0, 15   ; Executed

            // --- 메모리 읽기 및 부호 확장 검증 (IL-type LW / LH / LHU / LB / LBU) ---
            instr_rom[16] = 32'h00402583; // [PC 0x40] lw   x11, 4(x0)    ; Load Word: x11 = Mem[4] = 15 (0x0000000F)
            instr_rom[17] = 32'h00801603; // [PC 0x44] lh   x12, 8(x0)    ; Load Half (Signed): x12 = Mem[8]의 16비트 부호확장 => -10 (0xFFFFFFF6)
            instr_rom[18] = 32'h00805703; // [PC 0x48] lhu  x14, 8(x0)    ; Load Half (Unsigned): x14 = Mem[8]의 16비트 제로확장 => 65526 (0x0000FFF6)
            instr_rom[19] = 32'h00b00683; // [PC 0x4C] lb   x13, 11(x0)   ; Load Byte (Signed): x13 = Mem[11]의 8비트 부호확장 => -10 (0xFFFFFFF6)
            instr_rom[20] = 32'h00b04783; // [PC 0x50] lbu  x15, 11(x0)   ; Load Byte (Unsigned): x15 = Mem[11]의 8비트 제로확장 => 246 (0x000000F6)

            // --- 무조건 점프 및 복귀 (J-type JAL / I-type JALR) ---
            instr_rom[21] = 32'h00c008ef; // [PC 0x54] jal  x17, 12       ; JAL 점프: PC = 0x54 + 12 = 0x60로 이동 (x17 = 복귀주소 PC+4 = 0x58 저장)
            instr_rom[22] = 32'h06300913; // [PC 0x58] addi x18, x0, 99   ; Skipped (JAL 점프로 인해 실행되지 않음)
            instr_rom[23] = 32'h05800913; // [PC 0x5C] addi x18, x0, 88   ; Skipped (JAL 점프로 인해 실행되지 않음)
            instr_rom[24] = 32'h07000993; // [PC 0x60] addi x19, x0, 112  ; Executed: JAL의 타겟 지점. x19 = 112 (hex 0x70) 로드
            instr_rom[25] = 32'h00098a67; // [PC 0x64] jalr x20, 0(x19)   ; JALR 점프: PC = x19(112) + 0 = 112(0x70)로 이동 (x20 = 복귀주소 0x68 저장)
            instr_rom[26] = 32'h06300a93; // [PC 0x68] addi x21, x0, 99   ; Skipped (JALR 점프로 인해 실행되지 않음)
            instr_rom[27] = 32'h05800a93; // [PC 0x6C] addi x21, x0, 88   ; Skipped (JALR 점프로 인해 실행되지 않음)
            instr_rom[28] = 32'h00100b13; // [PC 0x70] addi x22, x0, 1    ; Executed: JALR의 타겟 지점. 최종 완료 플래그 적재 x22 = 1

            // --- 시뮬레이션 최종 종료를 위한 NOP 패딩 및 덤프 대기 ---
            for (int i = 29; i < 128; i = i + 1) begin
                instr_rom[i] = 32'h00000013; // nop (addi x0, x0, 0)
            end
        end
`ifdef TEST_SIMULATION
    initial begin
        $readmemh("rom_code.mem", instr_rom);
    end
    
`endif
    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule