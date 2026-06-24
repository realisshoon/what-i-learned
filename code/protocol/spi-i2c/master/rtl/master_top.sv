`timescale 1ns / 1ps

module master_top (
    input logic clk,

    // buttons
    input logic btnU,  // SPI start
    input logic btnL,  // I2C start
    input logic btnC,  // reset

    // switches
    input logic [7:0] sw,

    // SPI pins
    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs_n,

    // I2C pins
    output logic i2c_scl,
    inout  wire  i2c_sda,

    // LEDs
    output logic [15:0] led,

    // FND pins
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------
    logic reset;
    assign reset = btnC;

    // ------------------------------------------------------------
    // Button debounce / pulse
    // ------------------------------------------------------------
    logic spi_start_pulse;
    logic i2c_start_pulse;

    button_debounce U_BTN_SPI_START (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btnU),
        .o_btn(spi_start_pulse)
    );

    button_debounce U_BTN_I2C_START (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btnL),
        .o_btn(i2c_start_pulse)
    );

    // ------------------------------------------------------------
    // Protocol mode
    // ------------------------------------------------------------
    typedef enum logic [1:0] {
        DISP_IDLE = 2'd0,
        DISP_SPI  = 2'd1,
        DISP_I2C  = 2'd2
    } disp_mode_e;

    disp_mode_e       display_mode;

    // ------------------------------------------------------------
    // SPI signals
    // ------------------------------------------------------------
    logic             spi_start_valid;
    logic             spi_busy;
    logic             spi_done;
    logic       [7:0] spi_rx_data;
    logic       [7:0] spi_rx_latched;
    logic             spi_done_toggle;

    // ------------------------------------------------------------
    // I2C signals
    // ------------------------------------------------------------
    logic             i2c_start_valid;
    logic             i2c_busy;
    logic             i2c_done;
    logic       [7:0] i2c_rx_data;
    logic       [7:0] i2c_rx_latched;
    logic             i2c_done_toggle;
    logic             i2c_ack_ok;

    // ------------------------------------------------------------
    // Global busy
    // ------------------------------------------------------------
    logic             global_busy;
    assign global_busy = spi_busy | i2c_busy;

    assign spi_start_valid = spi_start_pulse & ~global_busy;
    assign i2c_start_valid = i2c_start_pulse & ~global_busy;

    // ------------------------------------------------------------
    // Display mode / result latch
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            display_mode    <= DISP_IDLE;

            spi_rx_latched  <= 8'd0;
            i2c_rx_latched  <= 8'd0;

            spi_done_toggle <= 1'b0;
            i2c_done_toggle <= 1'b0;
        end else begin
            if (spi_start_valid) begin
                display_mode <= DISP_SPI;
            end else if (i2c_start_valid) begin
                display_mode <= DISP_I2C;
            end

            if (spi_done) begin
                spi_rx_latched  <= spi_rx_data;
                spi_done_toggle <= ~spi_done_toggle;
            end

            if (i2c_done) begin
                i2c_rx_latched  <= i2c_rx_data;
                i2c_done_toggle <= ~i2c_done_toggle;
            end
        end
    end

    // ------------------------------------------------------------
    // SPI Master
    // 기존 SPI master를 직접 사용
    // ------------------------------------------------------------
    spi_master U_SPI_MASTER (
        .clk  (clk),
        .reset(reset),

        .start  (spi_start_valid),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd100),

        .tx_data(sw),
        .tx_busy(spi_busy),
        .rx_data(spi_rx_data),
        .rx_done(spi_done),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );

    // ------------------------------------------------------------
    // I2C Transaction Top
    // start 한 번으로 WRITE + READ transaction 수행
    // 내부에 i2c_cmd_controller + i2c_master_top 포함
    // ------------------------------------------------------------
    i2c_transaction_top #(
        .SLAVE_ADDR(7'h12)
    ) U_I2C_TRANSACTION_TOP (
        .clk(clk),
        .rst(reset),

        .start  (i2c_start_valid),
        .tx_data(sw),

        .rx_data(i2c_rx_data),
        .busy   (i2c_busy),
        .done   (i2c_done),

        .ack_ok(i2c_ack_ok),

        .scl(i2c_scl),
        .sda(i2c_sda)
    );

    // ------------------------------------------------------------
    // LED mux
    // ------------------------------------------------------------
    always_comb begin
        led = 16'd0;

        case (display_mode)

            DISP_SPI: begin
                led[7:0] = spi_rx_latched;
                led[8]   = 1'b1;  // SPI mode indicator
                led[9]   = 1'b0;
                led[10]  = spi_busy;
                led[11]  = spi_done_toggle;
                led[15]  = 1'b0;  // SPI에는 ACK 없음
            end

            DISP_I2C: begin
                led[7:0] = i2c_rx_latched;
                led[8]   = 1'b0;
                led[9]   = 1'b1;  // I2C mode indicator
                led[10]  = i2c_busy;
                led[11]  = i2c_done_toggle;
                led[15]  = i2c_ack_ok;  // ACK OK 표시
            end

            default: begin
                led = 16'd0;
            end

        endcase
    end

    // ------------------------------------------------------------
    // FND display
    // ------------------------------------------------------------
    fnd_protocol_controller U_FND_PROTOCOL_CONTROLLER (
        .clk     (clk),
        .rst     (reset),
        .mode    (display_mode),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );
endmodule
