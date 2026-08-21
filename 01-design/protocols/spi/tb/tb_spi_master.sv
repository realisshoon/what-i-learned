`timescale 1ns / 1ps


module tb_spi_master ();
    logic       clk;
    logic       reset;
    // internal signals
    logic       start;
    logic [7:0] clk_div;
    logic [7:0] tx_data;
    logic       busy;
    logic [7:0] rx_data;
    logic       done;
    logic       cpol;
    logic       cpha;
    // external signals
    logic       sclk;
    // logic       mosi;
    // logic       miso;
    logic       ss_n;
    logic       loop_wire;

    // Clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    spi_master dut (
        .clk    (clk),
        .reset  (reset),
        .start  (start),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .busy   (busy),
        .rx_data(rx_data),
        .done   (done),
        .sclk   (sclk),
        .mosi   (loop_wire),
        .miso   (loop_wire),
        .ss_n   (ss_n),
        .cpol   (cpol),
        .cpha   (cpha)
    );

    task spi_set_mode(bit [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask

    task spi_send_data(logic [7:0] data);
        tx_data = data;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (done);
        $display("Sent: 0x%02h, Received: 0x%02h", data, rx_data);
        @(posedge clk);
    endtask

    initial begin
        start   = 0;
        clk_div = 0;
        tx_data = 0;
        cpol    = 0;
        cpha    = 0;
        reset   = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz ->(100Mhz /(10Mhz*2)) - 1
        @(posedge clk);

        spi_set_mode(0);
        spi_send_data(8'haa);

        spi_set_mode(1);
        spi_send_data(8'haa);
        spi_set_mode(2);
        spi_send_data(8'haa);
        spi_set_mode(3);
        spi_send_data(8'haa);
        $finish;
    end


endmodule
