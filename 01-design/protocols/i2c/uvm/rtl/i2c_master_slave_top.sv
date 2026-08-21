`timescale 1ns / 1ps

module i2c_master_slave_top #(
    parameter logic [6:0] SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic reset,

    // Master command
    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    // Master side data/control
    input  logic [7:0] master_tx_data,
    output logic [7:0] master_rx_data,

    input  logic ack_in,  // read 후 Master가 보낼 ACK/NACK, ACK=0, NACK=1
    output logic ack_out, // write/address 후 Slave에게서 받은 ACK/NACK

    output logic master_busy,
    output logic master_done,

    // Slave side data/status
    input  logic [7:0] slave_tx_data,
    output logic [7:0] slave_rx_data,
    output logic       slave_rx_done,
    output logic       slave_tx_done,

    output logic slave_addr_match,
    output logic slave_rw_mode,
    output logic slave_master_ack,
    output logic slave_busy,

    // I2C line observe
    output wire scl,
    output wire sda
);

    wire  w_scl;
    wire  w_sda;

    logic master_sda_o;
    logic master_sda_i;

    assign scl = w_scl;
    assign sda = w_sda;

    // Master가 보는 SDA 입력
    assign master_sda_i = w_sda;

    // Master open-drain drive
    // master_sda_o = 0 : SDA Low drive
    // master_sda_o = 1 : SDA release
    assign w_sda = master_sda_o ? 1'bz : 1'b0;

    // Simulation pull-up
    pullup (w_sda);

    i2c_master u_i2c_master (
        .clk(clk),
        .rst(reset),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),

        .tx_data(master_tx_data),
        .rx_data(master_rx_data),

        .ack_in (master_read_ack),
        .ack_out(slave_ack_received),

        .busy(master_busy),
        .done(master_done),

        .scl  (w_scl),
        .sda_o(master_sda_o),
        .sda_i(master_sda_i)
    );

    i2c_slave_top #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_i2c_slave_top (
        .clk(clk),
        .rst(reset),

        .scl(w_scl),
        .sda(w_sda),

        .tx_data(slave_tx_data),

        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done),
        .tx_done(slave_tx_done),

        .addr_match(slave_addr_match),
        .rw_mode   (slave_rw_mode),
        .master_ack(slave_master_ack),
        .busy      (slave_busy)
    );

endmodule
