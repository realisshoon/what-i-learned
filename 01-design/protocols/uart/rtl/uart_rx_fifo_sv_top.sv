`timescale 1ns / 1ps

module uart_rx_fifo_sv_top(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    input  logic       pop,
    output logic [7:0] pop_data,
    output logic       full,
    output logic       empty,
    output logic       rx_err_frame
);

    logic w_tick;
    logic [7:0] w_rx_data;
    logic w_rx_done;

    baud_tick_gen U_BAUD_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    uart_rx_sv U_UART_RX(
        .clk(clk),
        .rst(rst),
        .b_tick(w_tick),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .rx_err_frame(rx_err_frame)
    );

    fifo_sv U_FIFO(
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_data),
        .push(w_rx_done),
        .pop(pop),
        .pop_data(pop_data),
        .full(full),
        .empty(empty)
    );

endmodule
