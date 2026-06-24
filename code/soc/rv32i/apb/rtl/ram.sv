`timescale 1ns / 1ps
`include "define.vh"

module ram (
    input  logic        clk,
    input  logic        R_REQ,
    input  logic        W_REQ,
    input  logic [2:0]  mem_mode,
    input  logic [31:0] Addr,
    input  logic [31:0] WDATA,
    output logic [31:0] RDATA
);

logic [31:0] data_ram [0:63];
logic [31:0] read_word;

assign read_word = data_ram[Addr[31:2]];

always_ff @(posedge clk) begin
    if (W_REQ) begin
        case(mem_mode)
            `SW:
                data_ram[Addr[31:2]] <= WDATA;
            `SB: begin
                if (Addr[1:0] == 2'b00)      data_ram[Addr[31:2]][7:0]   <= WDATA[7:0];
                else if (Addr[1:0] == 2'b01) data_ram[Addr[31:2]][15:8]  <= WDATA[7:0];
                else if (Addr[1:0] == 2'b10) data_ram[Addr[31:2]][23:16] <= WDATA[7:0];
                else                          data_ram[Addr[31:2]][31:24] <= WDATA[7:0];
            end
            `SH: begin
                if (Addr[1] == 1'b0)         data_ram[Addr[31:2]][15:0]  <= WDATA[15:0];
                else                          data_ram[Addr[31:2]][31:16] <= WDATA[15:0];
            end
        endcase
    end
end
always_comb begin
    RDATA = read_word;
    case (mem_mode)
        `LW: // LW (Load Word): 32비트 그대로 출력
            RDATA = read_word;

        `LB: // LB (Load Byte): 8비트만 골라내고 32비트로 부호 확장
            case (Addr[1:0]) // 잘라냈던 하위 2비트(00, 01, 10, 11)
                2'b00: RDATA = {{24{read_word[7]}},  read_word[7:0]};   // 0번째 바이트
                2'b01: RDATA = {{24{read_word[15]}}, read_word[15:8]};  // 1번째 바이트
                2'b10: RDATA = {{24{read_word[23]}}, read_word[23:16]}; // 2번째 바이트
                2'b11: RDATA = {{24{read_word[31]}}, read_word[31:24]}; // 3번째 바이트
            endcase

        `LH: // LH (Load Halfword): 16비트만 골라내고 부호 확장
            case (Addr[1])
                1'b0: RDATA = {{16{read_word[15]}}, read_word[15:0]};   // 앞쪽 절반
                1'b1: RDATA = {{16{read_word[31]}}, read_word[31:16]};  // 뒤쪽 절반
            endcase

        `LBU: // LBU (Load Byte Unsigned): 8비트만 골라내고 제로 확장
            case (Addr[1:0])
                2'b00: RDATA = {24'b0, read_word[7:0]};
                2'b01: RDATA = {24'b0, read_word[15:8]};
                2'b10: RDATA = {24'b0, read_word[23:16]};
                2'b11: RDATA = {24'b0, read_word[31:24]};
            endcase

        `LHU: // LHU (Load Halfword Unsigned): 16비트만 골라내고 제로 확장
            case (Addr[1])
                1'b0: RDATA = {16'b0, read_word[15:0]};
                1'b1: RDATA = {16'b0, read_word[31:16]};
            endcase
    endcase
end

endmodule
