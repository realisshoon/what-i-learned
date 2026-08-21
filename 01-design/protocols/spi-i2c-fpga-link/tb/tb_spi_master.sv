`timescale 1ns / 1ps

module tb_spi_master_slave;

    // global
    logic       clk;
    logic       reset;

    // master control
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;

    // master side
    logic [7:0] master_tx_data;
    logic       master_tx_busy;
    logic [7:0] master_rx_data;
    logic       master_rx_done;

    // spi lines
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;

    // slave side
    logic [7:0] slave_tx_data;
    logic       slave_tx_busy;
    logic [7:0] slave_rx_data;
    logic       slave_rx_done;

    // clock generation: 100MHz
    always #5 clk = ~clk;

    // ============================================================
    // Master DUT
    // ============================================================
    spi_master u_spi_master (
        .clk  (clk),
        .reset(reset),

        .start  (start),
        .cpol   (cpol),
        .cpha   (cpha),
        .clk_div(clk_div),

        .tx_data(master_tx_data),
        .tx_busy(master_tx_busy),
        .rx_data(master_rx_data),
        .rx_done(master_rx_done),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    // ============================================================
    // Slave DUT - Mode0, clk-based edge detect
    // ============================================================
    spi_slave u_spi_slave (
        .clk  (clk),
        .reset(reset),

        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),

        .tx_data(slave_tx_data),
        .tx_busy(slave_tx_busy),
        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done)
    );

    // ============================================================
    // SPI transfer task
    // ============================================================
    task automatic spi_transfer(input logic [7:0] m_tx, input logic [7:0] s_tx);
        begin
            master_tx_data = m_tx;
            slave_tx_data  = s_tx;

            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // slave synchronizer 지연 때문에 master/slave done 둘 다 기다림
            wait (master_rx_done == 1'b1);
            wait (slave_rx_done == 1'b1);

            @(posedge clk);

            $display("======================================");
            $display("[SPI TRANSFER]");
            $display("Master TX = 0x%02h, Slave RX = 0x%02h", master_tx_data, slave_rx_data);
            $display("Slave  TX = 0x%02h, Master RX = 0x%02h", slave_tx_data, master_rx_data);

            if (slave_rx_data !== master_tx_data) begin
                $display("[FAIL] Slave RX mismatch. Expected 0x%02h, Got 0x%02h", master_tx_data,
                         slave_rx_data);
            end else begin
                $display("[PASS] Slave RX matched");
            end

            if (master_rx_data !== slave_tx_data) begin
                $display("[FAIL] Master RX mismatch. Expected 0x%02h, Got 0x%02h", slave_tx_data,
                         master_rx_data);
            end else begin
                $display("[PASS] Master RX matched");
            end

            repeat (10) @(posedge clk);
        end
    endtask

    // ============================================================
    // Test scenario
    // ============================================================
    initial begin
        // init
        clk            = 1'b0;
        reset          = 1'b1;
        start          = 1'b0;

        cpol           = 1'b0;  // Mode0
        cpha           = 1'b0;  // Mode0

        // synchronizer 기반 slave라서 처음엔 느리게 검증
        clk_div        = 8'd20;

        master_tx_data = 8'd0;
        slave_tx_data  = 8'd0;

        // reset
        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (10) @(posedge clk);

        // test cases
        spi_transfer(8'hAA, 8'h55);
        spi_transfer(8'hFF, 8'h00);
        spi_transfer(8'h00, 8'hFF);
        spi_transfer(8'h3C, 8'hC3);

        repeat (20) @(posedge clk);

        $display("SPI Master-Slave Test Finished");

        $finish;
    end

endmodule
