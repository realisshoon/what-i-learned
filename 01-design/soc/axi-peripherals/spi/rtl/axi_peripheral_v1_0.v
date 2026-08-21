
`timescale 1 ns / 1 ps

module axi_peripheral_v1_0 #(

    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 7
) (
    // Users to add ports here
    output wire [7:0] gpio_led,
    output wire       board2_reset_n,
    output wire       board2_start,
    output wire [1:0] board2_mode,

    input wire [7:0] gpio_sw,
    input wire       board2_ready,
    input wire       board2_done,
    input wire       board2_error,

    output wire spi_sclk,
    output wire spi_mosi,
    input  wire spi_miso,
    output wire spi_cs_n,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);
    wire       spi_start;
    wire [7:0] spi_tx_data;
    wire [7:0] spi_clk_div;
    wire       spi_cpol;
    wire       spi_cpha;
    wire       spi_busy;
    wire       spi_done;
    wire [7:0] spi_rx_data;
    wire       spi_error;
    wire       spi_reset;

    assign spi_error = 1'b0;
    assign spi_reset = ~s00_axi_aresetn;

    // Instantiation of Axi Bus Interface S00_AXI
    axi_peripheral_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) axi_peripheral_v1_0_S00_AXI_inst (
        // User ports
        .gpio_led      (gpio_led),
        .board2_reset_n(board2_reset_n),
        .board2_start  (board2_start),
        .board2_mode   (board2_mode),

        .gpio_sw     (gpio_sw),
        .board2_ready(board2_ready),
        .board2_done (board2_done),
        .board2_error(board2_error),

        .spi_start  (spi_start),
        .spi_tx_data(spi_tx_data),
        .spi_clk_div(spi_clk_div),
        .spi_cpol   (spi_cpol),
        .spi_cpha   (spi_cpha),
        .spi_busy   (spi_busy),
        .spi_done   (spi_done),
        .spi_rx_data(spi_rx_data),
        .spi_error  (spi_error),

        // AXI ports
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // Add user logic here
    spi_master u_spi_master (
        .clk    (s00_axi_aclk),
        .reset  (spi_reset),

        .start  (spi_start),
        .cpol   (spi_cpol),
        .cpha   (spi_cpha),
        .clk_div(spi_clk_div),

        .tx_data(spi_tx_data),
        .tx_busy(spi_busy),
        .rx_data(spi_rx_data),
        .rx_done(spi_done),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );

    // User logic ends

endmodule
