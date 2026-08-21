`timescale 1ns / 1ps

module spi_i2c_top #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int I2C_FREQ_HZ = 100_000,
    parameter logic [6:0] I2C_SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic reset,

    // SPI master control
    input logic       spi_start,
    input logic       spi_cpol,
    input logic       spi_cpha,
    input logic [7:0] spi_clk_div,

    // SPI user data
    input logic [7:0] spi_master_tx_data,
    input logic [7:0] spi_slave_tx_data,

    // SPI observe
    output logic       spi_master_tx_busy,
    output logic [7:0] spi_master_rx_data,
    output logic       spi_master_rx_done,
    output logic       spi_slave_tx_busy,
    output logic [7:0] spi_slave_rx_data,
    output logic       spi_slave_rx_done,
    output logic       spi_sclk,
    output logic       spi_mosi,
    output logic       spi_miso,
    output logic       spi_cs_n,

    // I2C master command
    input logic       i2c_cmd_start,
    input logic       i2c_cmd_write,
    input logic       i2c_cmd_read,
    input logic       i2c_cmd_stop,
    input logic [7:0] i2c_master_tx_data,
    input logic       i2c_ack_in,

    // I2C master observe
    output logic [7:0] i2c_master_rx_data,
    output logic       i2c_ack_out,
    output logic       i2c_master_busy,
    output logic       i2c_master_done,

    // I2C slave data
    input logic [7:0] i2c_slave_tx_data,

    // I2C slave observe
    output logic [7:0] i2c_slave_rx_data,
    output logic       i2c_slave_rx_done,
    output logic       i2c_slave_tx_done,
    output logic       i2c_slave_addr_match,
    output logic       i2c_slave_rw_mode,
    output logic       i2c_slave_master_ack,
    output logic       i2c_slave_busy,

    // I2C bus observe
    output logic i2c_scl,
    output logic i2c_sda,
    output logic i2c_master_sda_release,
    output logic i2c_slave_sda_drive_low
);

    logic i2c_sda_line;

    // Internal open-drain model:
    // master release=1 and slave drive_low=0 makes the pulled-up SDA line high.
    assign i2c_sda_line = i2c_master_sda_release & ~i2c_slave_sda_drive_low;
    assign i2c_sda      = i2c_sda_line;

    spi_i2c_master_top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .I2C_FREQ_HZ(I2C_FREQ_HZ)
    ) u_spi_i2c_master_top (
        .clk            (clk),
        .reset          (reset),
        .spi_start      (spi_start),
        .spi_cpol       (spi_cpol),
        .spi_cpha       (spi_cpha),
        .spi_clk_div    (spi_clk_div),
        .spi_tx_data    (spi_master_tx_data),
        .spi_tx_busy    (spi_master_tx_busy),
        .spi_rx_data    (spi_master_rx_data),
        .spi_rx_done    (spi_master_rx_done),
        .spi_sclk       (spi_sclk),
        .spi_mosi       (spi_mosi),
        .spi_miso       (spi_miso),
        .spi_cs_n       (spi_cs_n),
        .i2c_cmd_start  (i2c_cmd_start),
        .i2c_cmd_write  (i2c_cmd_write),
        .i2c_cmd_read   (i2c_cmd_read),
        .i2c_cmd_stop   (i2c_cmd_stop),
        .i2c_tx_data    (i2c_master_tx_data),
        .i2c_ack_in     (i2c_ack_in),
        .i2c_rx_data    (i2c_master_rx_data),
        .i2c_ack_out    (i2c_ack_out),
        .i2c_busy       (i2c_master_busy),
        .i2c_done       (i2c_master_done),
        .i2c_scl        (i2c_scl),
        .i2c_sda_release(i2c_master_sda_release),
        .i2c_sda_i      (i2c_sda_line)
    );

    spi_i2c_slave_top #(
        .I2C_SLAVE_ADDR(I2C_SLAVE_ADDR)
    ) u_spi_i2c_slave_top (
        .clk              (clk),
        .reset            (reset),
        .spi_sclk         (spi_sclk),
        .spi_mosi         (spi_mosi),
        .spi_miso         (spi_miso),
        .spi_cs_n         (spi_cs_n),
        .spi_tx_data      (spi_slave_tx_data),
        .spi_rx_data      (spi_slave_rx_data),
        .spi_rx_done      (spi_slave_rx_done),
        .spi_tx_busy      (spi_slave_tx_busy),
        .i2c_scl          (i2c_scl),
        .i2c_sda_i        (i2c_sda_line),
        .i2c_sda_drive_low(i2c_slave_sda_drive_low),
        .i2c_tx_data      (i2c_slave_tx_data),
        .i2c_rx_data      (i2c_slave_rx_data),
        .i2c_rx_done      (i2c_slave_rx_done),
        .i2c_tx_done      (i2c_slave_tx_done),
        .i2c_addr_match   (i2c_slave_addr_match),
        .i2c_rw_mode      (i2c_slave_rw_mode),
        .i2c_master_ack   (i2c_slave_master_ack),
        .i2c_busy         (i2c_slave_busy)
    );

endmodule
