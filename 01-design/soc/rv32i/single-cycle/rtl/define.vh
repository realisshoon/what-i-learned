// opcode [6:0]
`define R_TYPE   7'b011_0011
`define S_TYPE   7'b010_0011
`define IL_TYPE  7'b000_0011
`define I_TYPE   7'b001_0011
`define B_TYPE   7'b110_0011
`define LU_TYPE  7'b011_0111
`define AU_TYPE  7'b001_0111
`define J_TYPE   7'b110_1111
`define JL_TYPE  7'b110_0111

// R-type instruction
// {funct 7, funct3}
`define ADD 4'b0000
`define SUB 4'b1000
`define SLL 4'b0001
`define SLT 4'b0010
`define SLTU 4'b0011
`define XOR 4'b0100
`define SRL 4'b0101
`define SRA 4'b1101
`define OR 4'b0110
`define AND 4'b0111


// S-Type Instruction

`define SB 3'b000
`define SH 3'b001
`define SW 3'b010


// IL-Type Instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101


// I-Type Instruction
`define ADDI  3'b000
`define SLLI  3'b001
`define SLTI  3'b010
`define SLTIU 3'b011
`define XORI  3'b100
`define SRLI  3'b101
`define SRAI  3'b101
`define ORI   3'b110
`define ANDI  3'b111


// B-Type Instrunction
`define BEQ 3'b000
`define BNE 3'b001
`define BLT 3'b100
`define BGE 3'b101
`define BLTU 3'b110
`define BGEU 3'b111


