`timescale 1ns / 1ps

module spi_master_slave_top (
    input logic clk,
    input logic reset,

    // master control
    input logic       start,
    input logic [7:0] clk_div,

    // user data
    input logic [7:0] master_tx_data,
    input logic [7:0] slave_tx_data,

    // observe
    output logic       master_tx_busy,
    output logic [7:0] master_rx_data,
    output logic       master_rx_done,

    output logic       slave_tx_busy,
    output logic [7:0] slave_rx_data,
    output logic       slave_rx_done,

    // optional observe SPI lines
    output logic sclk,
    output logic mosi,
    output logic miso,
    output logic cs_n
);

    logic w_sclk;
    logic w_mosi;
    logic w_miso;
    logic w_cs_n;

    assign sclk = w_sclk;
    assign mosi = w_mosi;
    assign miso = w_miso;
    assign cs_n = w_cs_n;

    spi_master u_spi_master (
        .clk  (clk),
        .reset(reset),

        .start  (start),
        .clk_div(clk_div),
        .tx_data(master_tx_data),

        .tx_busy(master_tx_busy),
        .rx_data(master_rx_data),
        .rx_done(master_rx_done),

        .sclk(w_sclk),
        .mosi(w_mosi),
        .miso(w_miso),
        .cs_n(w_cs_n)
    );
    spi_slave u_spi_slave (
        .clk  (clk),
        .reset(reset),

        .sclk(w_sclk),
        .mosi(w_mosi),
        .miso(w_miso),
        .cs_n(w_cs_n),

        .tx_data(slave_tx_data),

        .tx_busy(slave_tx_busy),
        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done)
    );

endmodule
