`timescale 1ns / 1ps

module slave_top (
    input logic clk,
    input logic reset,

    input logic [7:0] sw,

    // SPI pins
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,

    // I2C pins
    input logic i2c_scl,
    inout wire  i2c_sda,

    // LEDs
    output logic [15:0] led,

    // FND
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    // ------------------------------------------------------------
    // Common latch
    // ------------------------------------------------------------
    logic [7:0] master_tx_latched;

    // ------------------------------------------------------------
    // SPI signals
    // ------------------------------------------------------------
    logic [7:0] spi_rx_data;
    logic       spi_rx_done;
    logic       spi_tx_busy;

    // ------------------------------------------------------------
    // I2C signals
    // ------------------------------------------------------------
    logic [7:0] i2c_rx_data;
    logic       i2c_rx_done;
    logic       i2c_tx_done;
    logic       i2c_addr_match;
    logic       i2c_rw_mode;
    logic       i2c_master_ack;
    logic       i2c_busy;

    // ------------------------------------------------------------
    // Status toggles
    // ------------------------------------------------------------
    logic       spi_done_toggle;
    logic       i2c_rx_toggle;
    logic       i2c_tx_toggle;

    // ------------------------------------------------------------
    // SPI Slave
    // ------------------------------------------------------------
    spi_slave U_SPI_SLAVE (
        .clk  (clk),
        .reset(reset),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n),

        .tx_data(sw),
        .rx_data(spi_rx_data),
        .rx_done(spi_rx_done),
        .tx_busy(spi_tx_busy)
    );

    // ------------------------------------------------------------
    // I2C Slave
    // ------------------------------------------------------------
    i2c_slave_top #(
        .SLAVE_ADDR(7'h12)
    ) U_I2C_SLAVE_TOP (
        .clk(clk),
        .rst(reset),

        .scl(i2c_scl),
        .sda(i2c_sda),

        .tx_data(sw),

        .rx_data(i2c_rx_data),
        .rx_done(i2c_rx_done),
        .tx_done(i2c_tx_done),

        .addr_match(i2c_addr_match),
        .rw_mode   (i2c_rw_mode),
        .master_ack(i2c_master_ack),
        .busy      (i2c_busy)
    );

    // ------------------------------------------------------------
    // Master TX latch
    // SPI 또는 I2C로 Master가 보낸 값을 저장
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            master_tx_latched <= 8'h00;
        end else begin
            if (spi_rx_done) begin
                master_tx_latched <= spi_rx_data;
            end

            if (i2c_rx_done) begin
                master_tx_latched <= i2c_rx_data;
            end
        end
    end

    // ------------------------------------------------------------
    // FND: Master TX 값을 HEX로 표시
    // 예: 8'h55 -> 0055, 8'hA5 -> 00A5
    // ------------------------------------------------------------
    fnd_hex_controller U_SLAVE_FND_HEX (
        .clk     (clk),
        .rst     (reset),
        .hex_in  ({8'h00, master_tx_latched}),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    // ------------------------------------------------------------
    // LED status toggles
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_done_toggle <= 1'b0;
            i2c_rx_toggle   <= 1'b0;
            i2c_tx_toggle   <= 1'b0;
        end else begin
            if (spi_rx_done) begin
                spi_done_toggle <= ~spi_done_toggle;
            end

            if (i2c_rx_done) begin
                i2c_rx_toggle <= ~i2c_rx_toggle;
            end

            if (i2c_tx_done) begin
                i2c_tx_toggle <= ~i2c_tx_toggle;
            end
        end
    end

    // ------------------------------------------------------------
    // LED status
    // ------------------------------------------------------------
    always_comb begin
        led      = 16'd0;

        // SPI/I2C 상관없이 Master가 마지막으로 보낸 TX 값
        led[7:0] = master_tx_latched;

        // status
        led[8]   = spi_done_toggle;  // SPI 수신 완료 토글
        led[9]   = i2c_rx_toggle;  // I2C write 수신 완료 토글
        led[10]  = i2c_addr_match;  // I2C 주소 match
        led[11]  = i2c_rw_mode;  // 0=write, 1=read
        led[12]  = i2c_tx_toggle;  // I2C read 응답 완료 토글
        led[13]  = i2c_master_ack;  // Master ACK/NACK, ACK=0, NACK=1
        led[14]  = spi_tx_busy;  // SPI busy
        led[15]  = i2c_busy;  // I2C busy
    end

endmodule
