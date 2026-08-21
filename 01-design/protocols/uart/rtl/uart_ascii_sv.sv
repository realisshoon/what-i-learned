`timescale 1ns / 1ps

module ascii_decoder (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] ascii_in,
    input  logic       read_en,
    output logic [4:0] ascii_out
);

    localparam logic [4:0] ASCII_S = 5'b00001;
    localparam logic [4:0] ASCII_2 = 5'b00010;
    localparam logic [4:0] ASCII_4 = 5'b00100;
    localparam logic [4:0] ASCII_6 = 5'b01000;
    localparam logic [4:0] ASCII_8 = 5'b10000;

    logic [4:0] one_pulse_reg;
    logic [4:0] one_pulse_delay;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            one_pulse_reg <= 5'b00000;
        end else if (read_en) begin
            case (ascii_in)
                8'h73:   one_pulse_reg <= ASCII_S;
                8'h32:   one_pulse_reg <= ASCII_2;
                8'h34:   one_pulse_reg <= ASCII_4;
                8'h36:   one_pulse_reg <= ASCII_6;
                8'h38:   one_pulse_reg <= ASCII_8;
                default: one_pulse_reg <= 5'b00000;
            endcase
        end else begin
            one_pulse_reg <= 5'b00000;
        end
    end


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            one_pulse_delay <= 5'b00000;
        end else begin
            one_pulse_delay <= one_pulse_reg;
        end
    end

    assign ascii_out = one_pulse_reg & (~one_pulse_delay);

endmodule