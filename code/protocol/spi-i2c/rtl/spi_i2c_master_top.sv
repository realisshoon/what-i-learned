`timescale 1ns / 1ps

module spi_i2c_master_top #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int I2C_FREQ_HZ = 100_000
) (
    input logic clk,
    input logic reset,

    // SPI master control
    input logic       spi_start,
    input logic       spi_cpol,
    input logic       spi_cpha,
    input logic [7:0] spi_clk_div,

    // SPI master data
    input  logic [7:0] spi_tx_data,
    output logic       spi_tx_busy,
    output logic [7:0] spi_rx_data,
    output logic       spi_rx_done,

    // SPI bus
    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs_n,

    // I2C master command
    input logic       i2c_cmd_start,
    input logic       i2c_cmd_write,
    input logic       i2c_cmd_read,
    input logic       i2c_cmd_stop,
    input logic [7:0] i2c_tx_data,
    input logic       i2c_ack_in,

    // I2C master data/status
    output logic [7:0] i2c_rx_data,
    output logic       i2c_ack_out,
    output logic       i2c_busy,
    output logic       i2c_done,

    // I2C bus
    output logic i2c_scl,
    output logic i2c_sda_release,
    input  logic i2c_sda_i
);

    spi_master u_spi_master (
        .clk    (clk),
        .reset  (reset),
        .start  (spi_start),
        .cpol   (spi_cpol),
        .cpha   (spi_cpha),
        .clk_div(spi_clk_div),
        .tx_data(spi_tx_data),
        .tx_busy(spi_tx_busy),
        .rx_data(spi_rx_data),
        .rx_done(spi_rx_done),
        .sclk   (spi_sclk),
        .mosi   (spi_mosi),
        .miso   (spi_miso),
        .cs_n   (spi_cs_n)
    );

    i2c_master #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .I2C_FREQ_HZ(I2C_FREQ_HZ)
    ) u_i2c_master (
        .clk      (clk),
        .rst      (reset),
        .cmd_start(i2c_cmd_start),
        .cmd_write(i2c_cmd_write),
        .cmd_read (i2c_cmd_read),
        .cmd_stop (i2c_cmd_stop),
        .tx_data  (i2c_tx_data),
        .rx_data  (i2c_rx_data),
        .ack_in   (i2c_ack_in),
        .ack_out  (i2c_ack_out),
        .busy     (i2c_busy),
        .done     (i2c_done),
        .scl      (i2c_scl),
        .sda_o    (i2c_sda_release),
        .sda_i    (i2c_sda_i)
    );

endmodule
