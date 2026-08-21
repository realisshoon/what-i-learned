interface spi_if (
    input logic clk
);
    logic       reset;
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;


    logic       sclk;
    logic       cs_n;
    logic       mosi;
    logic       miso;

    logic [7:0] master_tx_data;
    logic       master_tx_busy;
    logic [7:0] master_rx_data;
    logic       master_rx_done;

    logic [7:0] slave_tx_data;
    logic       slave_tx_busy;
    logic [7:0] slave_rx_data;
    logic       slave_rx_done;





    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output reset;
        output start;
        output cpol;
        output cpha;
        output clk_div;
        output master_tx_data;
        output slave_tx_data;

        input master_tx_busy;
        input master_rx_done;
        input slave_tx_busy;
        input slave_rx_done;

    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input reset;
        input start;
        input cpol;
        input cpha;
        input clk_div;

        input master_tx_data;
        input master_tx_busy;
        input master_rx_done;
        input master_rx_data;

        input slave_rx_data;
        input slave_rx_done;
        input slave_tx_data;
        input slave_tx_busy;

        input sclk;
        input mosi;
        input miso;
        input cs_n;
    endclocking
endinterface
