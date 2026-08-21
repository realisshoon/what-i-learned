`timescale 1ns / 1ps

module spi_slave (
    input  logic       reset,
    input  logic       sclk,
    input  logic       cs_n,
    //
    input  logic       miso,
    input  logic       cpol,
    input  logic       cpha,
    output logic       mosi,
    //
    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic [7:0] rx_data,
    output logic       rx_done
);


    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;


    always_ff @(posedge cs_n or posedge reset) begin
        if (reset) begin
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            bit_cnt      <= 3'd0;
            rx_data      <= 8'd0;
            rx_done      <= 0;
            miso         <= 0;
        end else begin
            tx_shift_reg <= tx_data;
            rx_shift_reg <= 8'd0;
            bit_cnt      <= 0;
            rx_done      <= 0;
            miso         <= tx_data[7];
        end
    end

endmodule
