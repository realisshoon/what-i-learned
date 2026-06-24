`timescale 1ns / 1ps

module spi_master_fpga_top (
    input logic       clk,
    input logic       reset,
    input logic       btn_start,
    input logic [7:0] sw,

    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs_n,

    output logic [7:0] led,
    output logic       led_busy,
    output logic       led_done
);

    logic start_pulse;
    logic tx_busy;
    logic rx_done;
    logic [7:0] rx_data;

    button_debounce U_BTN_START (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_start),
        .o_btn(start_pulse)
    );

    spi_master U_SPI_MASTER (
        .clk  (clk),
        .reset(reset),

        .start  (start_pulse),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd100),

        .tx_data(sw),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_done(rx_done),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );
    logic done_toggle;
    logic busy_seen;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done_toggle <= 1'b0;
            busy_seen   <= 1'b0;
        end else begin
            if (tx_busy) busy_seen <= 1'b1;

            if (rx_done) done_toggle <= ~done_toggle;
        end
    end

    assign led_busy = busy_seen;
    assign led_done = done_toggle;
endmodule
