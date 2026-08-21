`timescale 1ns / 1ps

module spi_i2c_slave_top #(
    parameter logic [6:0] I2C_SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic reset,

    // SPI bus
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,

    // SPI slave data/status
    input  logic [7:0] spi_tx_data,
    output logic [7:0] spi_rx_data,
    output logic       spi_rx_done,
    output logic       spi_tx_busy,

    // I2C bus
    input  logic i2c_scl,
    input  logic i2c_sda_i,
    output logic i2c_sda_drive_low,

    // I2C slave data/status
    input  logic [7:0] i2c_tx_data,
    output logic [7:0] i2c_rx_data,
    output logic       i2c_rx_done,
    output logic       i2c_tx_done,
    output logic       i2c_addr_match,
    output logic       i2c_rw_mode,
    output logic       i2c_master_ack,
    output logic       i2c_busy
);

    spi_slave u_spi_slave (
        .clk    (clk),
        .reset  (reset),
        .sclk   (spi_sclk),
        .mosi   (spi_mosi),
        .miso   (spi_miso),
        .cs_n   (spi_cs_n),
        .tx_data(spi_tx_data),
        .rx_data(spi_rx_data),
        .rx_done(spi_rx_done),
        .tx_busy(spi_tx_busy)
    );

    i2c_slave_simple #(
        .SLAVE_ADDR(I2C_SLAVE_ADDR)
    ) u_i2c_slave (
        .clk          (clk),
        .rst          (reset),
        .scl          (i2c_scl),
        .sda_i        (i2c_sda_i),
        .sda_drive_low(i2c_sda_drive_low),
        .tx_data      (i2c_tx_data),
        .rx_data      (i2c_rx_data),
        .rx_done      (i2c_rx_done),
        .tx_done      (i2c_tx_done),
        .addr_match   (i2c_addr_match),
        .rw_mode      (i2c_rw_mode),
        .master_ack   (i2c_master_ack),
        .busy         (i2c_busy)
    );

endmodule
