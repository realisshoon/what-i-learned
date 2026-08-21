`timescale 1ns / 1ps

module tb_axi_peripheral;

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 7;

    // ------------------------------------------------------------
    // Clock / Reset
    // ------------------------------------------------------------
    logic clk;
    logic resetn;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    // ------------------------------------------------------------
    // AXI4-Lite signals
    // ------------------------------------------------------------
    logic [    ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [               2:0] s00_axi_awprot;
    logic                      s00_axi_awvalid;
    wire                       s00_axi_awready;

    logic [    DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic                      s00_axi_wvalid;
    wire                       s00_axi_wready;

    wire  [               1:0] s00_axi_bresp;
    wire                       s00_axi_bvalid;
    logic                      s00_axi_bready;

    logic [    ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [               2:0] s00_axi_arprot;
    logic                      s00_axi_arvalid;
    wire                       s00_axi_arready;

    wire  [    DATA_WIDTH-1:0] s00_axi_rdata;
    wire  [               1:0] s00_axi_rresp;
    wire                       s00_axi_rvalid;
    logic                      s00_axi_rready;

    // ------------------------------------------------------------
    // User ports
    // ------------------------------------------------------------
    wire  [               7:0] gpio_led;
    wire                       board2_reset_n;
    wire                       board2_start;
    wire  [               1:0] board2_mode;

    logic [               7:0] gpio_sw;
    logic                      board2_ready;
    logic                      board2_done;
    logic                      board2_error;

    wire                       spi_sclk;
    wire                       spi_mosi;
    wire                       spi_miso;
    wire                       spi_cs_n;

    logic [               7:0] spi_slave_tx_data;
    wire  [               7:0] spi_slave_rx_data;
    wire                       spi_slave_rx_done;
    wire                       spi_slave_tx_busy;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    axi_peripheral_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .gpio_led      (gpio_led),
        .board2_reset_n(board2_reset_n),
        .board2_start  (board2_start),
        .board2_mode   (board2_mode),

        .gpio_sw     (gpio_sw),
        .board2_ready(board2_ready),
        .board2_done (board2_done),
        .board2_error(board2_error),

        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),

        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(resetn),

        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),

        .s00_axi_wdata (s00_axi_wdata),
        .s00_axi_wstrb (s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),

        .s00_axi_bresp (s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),

        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),

        .s00_axi_rdata (s00_axi_rdata),
        .s00_axi_rresp (s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
    );

    spi_slave u_spi_slave_model (
        .clk  (clk),
        .reset(~resetn),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n),

        .tx_data(spi_slave_tx_data),
        .rx_data(spi_slave_rx_data),
        .rx_done(spi_slave_rx_done),
        .tx_busy(spi_slave_tx_busy)
    );

    // ------------------------------------------------------------
    // Address Map
    // ------------------------------------------------------------
    localparam logic [ADDR_WIDTH-1:0] ADDR_SYS_CTRL = 7'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SYS_STATUS = 7'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_GPIO_OUT = 7'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_GPIO_IN = 7'h0C;

    localparam logic [ADDR_WIDTH-1:0] ADDR_TIMER_CTRL = 7'h10;
    localparam logic [ADDR_WIDTH-1:0] ADDR_TIMER_STATUS = 7'h14;
    localparam logic [ADDR_WIDTH-1:0] ADDR_TIMER_COMPARE = 7'h18;
    localparam logic [ADDR_WIDTH-1:0] ADDR_TIMER_COUNT = 7'h1C;

    localparam logic [ADDR_WIDTH-1:0] ADDR_SPI_CTRL = 7'h20;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SPI_STATUS = 7'h24;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SPI_TXDATA = 7'h28;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SPI_RXDATA = 7'h2C;

    localparam logic [ADDR_WIDTH-1:0] ADDR_DEBUG0 = 7'h78;
    localparam logic [ADDR_WIDTH-1:0] ADDR_DEBUG1 = 7'h7C;

    // ------------------------------------------------------------
    // AXI write task
    // Vivado template expects AWVALID and WVALID together.
    // ------------------------------------------------------------
    task automatic axi_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            s00_axi_awaddr  <= addr;
            s00_axi_awprot  <= 3'b000;
            s00_axi_awvalid <= 1'b1;

            s00_axi_wdata   <= data;
            s00_axi_wstrb   <= 4'hF;
            s00_axi_wvalid  <= 1'b1;

            s00_axi_bready  <= 1'b1;

            wait (s00_axi_awready && s00_axi_wready);
            @(posedge clk);
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;
            s00_axi_awaddr  <= '0;
            s00_axi_wdata   <= '0;

            wait (s00_axi_bvalid);
            if (s00_axi_bresp != 2'b00) begin
                $error("[AXI WRITE] BRESP error. addr=0x%02h bresp=%0b", addr, s00_axi_bresp);
            end

            @(posedge clk);
            s00_axi_bready <= 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // AXI read task
    // ------------------------------------------------------------
    task automatic axi_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            s00_axi_araddr  <= addr;
            s00_axi_arprot  <= 3'b000;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            wait (s00_axi_arready);
            @(posedge clk);
            s00_axi_arvalid <= 1'b0;
            s00_axi_araddr  <= '0;

            wait (s00_axi_rvalid);
            data = s00_axi_rdata;

            if (s00_axi_rresp != 2'b00) begin
                $error("[AXI READ] RRESP error. addr=0x%02h rresp=%0b", addr, s00_axi_rresp);
            end

            @(posedge clk);
            s00_axi_rready <= 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Check task
    // ------------------------------------------------------------
    task automatic check32(input string name, input logic [31:0] actual,
                           input logic [31:0] expected);
        begin
            if (actual !== expected) begin
                $error("[FAIL] %s actual=0x%08h expected=0x%08h", name, actual, expected);
            end else begin
                $display("[PASS] %s = 0x%08h", name, actual);
            end
        end
    endtask

    task automatic wait_spi_done(output logic [DATA_WIDTH-1:0] status);
        int poll_count;
        bit done_seen;
        begin
            poll_count = 0;
            done_seen  = 1'b0;
            status     = '0;

            while (!done_seen && poll_count < 100) begin
                axi_read(ADDR_SPI_STATUS, status);
                done_seen = status[1];
                poll_count++;
                repeat (2) @(posedge clk);
            end

            if (!done_seen) begin
                $error("[FAIL] SPI done timeout. last_status=0x%08h", status);
            end else begin
                $display("[PASS] SPI done observed. status=0x%08h polls=%0d", status,
                         poll_count);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    logic [31:0] rdata;

    initial begin
        // waveform
        $dumpfile("tb_axi_peripheral.vcd");
        $dumpvars(0, tb_axi_peripheral);

        // initial values
        resetn          = 1'b0;

        s00_axi_awaddr  = '0;
        s00_axi_awprot  = '0;
        s00_axi_awvalid = 1'b0;

        s00_axi_wdata   = '0;
        s00_axi_wstrb   = '0;
        s00_axi_wvalid  = 1'b0;

        s00_axi_bready  = 1'b0;

        s00_axi_araddr  = '0;
        s00_axi_arprot  = '0;
        s00_axi_arvalid = 1'b0;

        s00_axi_rready  = 1'b0;

        gpio_sw         = 8'h00;
        board2_ready    = 1'b0;
        board2_done     = 1'b0;
        board2_error    = 1'b0;
        spi_slave_tx_data = 8'h00;

        // reset
        repeat (5) @(posedge clk);
        resetn = 1'b1;
        repeat (3) @(posedge clk);

        $display("========================================");
        $display(" AXI Peripheral Register Bank TB Start");
        $display("========================================");

        // --------------------------------------------------------
        // Test 1: GPIO_OUT write/read
        // Write 0x08 = 0xAA
        // --------------------------------------------------------
        $display("[TEST 1] GPIO_OUT write/read");
        axi_write(ADDR_GPIO_OUT, 32'h0000_00AA);
        axi_read(ADDR_GPIO_OUT, rdata);

        check32("GPIO_OUT readback", rdata, 32'h0000_00AA);

        if (gpio_led !== 8'hAA) begin
            $error("[FAIL] gpio_led actual=0x%02h expected=0xAA", gpio_led);
        end else begin
            $display("[PASS] gpio_led = 0x%02h", gpio_led);
        end

        // --------------------------------------------------------
        // Test 2: GPIO_OUT board2 control bits
        // bit[8] reset_n, bit[9] start, bit[11:10] mode
        // data = 0x0000_0D5A
        // bit[7:0] = 0x5A
        // bit[8]   = 1
        // bit[9]   = 0
        // bit[11:10] = 2'b11
        // --------------------------------------------------------
        $display("[TEST 2] GPIO_OUT bit field");
        axi_write(ADDR_GPIO_OUT, 32'h0000_0D5A);
        axi_read(ADDR_GPIO_OUT, rdata);

        check32("GPIO_OUT bitfield readback", rdata, 32'h0000_0D5A);

        if (gpio_led !== 8'h5A) $error("[FAIL] gpio_led actual=0x%02h expected=0x5A", gpio_led);
        else $display("[PASS] gpio_led = 0x%02h", gpio_led);

        if (board2_reset_n !== 1'b1)
            $error("[FAIL] board2_reset_n actual=%0b expected=1", board2_reset_n);
        else $display("[PASS] board2_reset_n = %0b", board2_reset_n);

        if (board2_start !== 1'b0)
            $error("[FAIL] board2_start actual=%0b expected=0", board2_start);
        else $display("[PASS] board2_start = %0b", board2_start);

        if (board2_mode !== 2'b11) $error("[FAIL] board2_mode actual=%0b expected=11", board2_mode);
        else $display("[PASS] board2_mode = %0b", board2_mode);

        // --------------------------------------------------------
        // Test 3: GPIO_IN read
        // gpio_sw      = 0x55
        // board2_ready = 1
        // board2_done  = 0
        // board2_error = 0
        // expected = 0x0000_0155
        // --------------------------------------------------------
        $display("[TEST 3] GPIO_IN read");
        gpio_sw      = 8'h55;
        board2_ready = 1'b1;
        board2_done  = 1'b0;
        board2_error = 1'b0;

        repeat (2) @(posedge clk);

        axi_read(ADDR_GPIO_IN, rdata);
        check32("GPIO_IN read", rdata, 32'h0000_0155);

        // --------------------------------------------------------
        // Test 4: GPIO_IN is R/O
        // Try to write GPIO_IN. Read value should still come from pins.
        // --------------------------------------------------------
        $display("[TEST 4] GPIO_IN R/O write ignored");
        axi_write(ADDR_GPIO_IN, 32'hFFFF_FFFF);
        axi_read(ADDR_GPIO_IN, rdata);
        check32("GPIO_IN after ignored write", rdata, 32'h0000_0155);

        // --------------------------------------------------------
        // Test 5: DEBUG0 R/W
        // --------------------------------------------------------
        $display("[TEST 5] DEBUG0 write/read");
        axi_write(ADDR_DEBUG0, 32'h1234_5678);
        axi_read(ADDR_DEBUG0, rdata);
        check32("DEBUG0 readback", rdata, 32'h1234_5678);

        // --------------------------------------------------------
        // Test 6: SPI_STATUS is R/O and currently tied to 0
        // --------------------------------------------------------
        $display("[TEST 6] SPI_STATUS R/O");
        axi_write(ADDR_SPI_STATUS, 32'hFFFF_FFFF);
        axi_read(ADDR_SPI_STATUS, rdata);
        check32("SPI_STATUS after ignored write", rdata, 32'h0000_0000);

        // --------------------------------------------------------
        // Test 7: AXI write -> SPI master -> SPI slave -> AXI read
        // Master TX = 0x3C, slave response = 0xA5
        // --------------------------------------------------------
        $display("[TEST 7] SPI master/slave transfer");
        spi_slave_tx_data = 8'hA5;

        axi_write(ADDR_SPI_CTRL, 32'h0000_0800);  // clk_div = 8, start = 0
        axi_write(ADDR_SPI_TXDATA, 32'h0000_003C);
        axi_write(ADDR_SPI_CTRL, 32'h0000_0801);  // start pulse

        axi_read(ADDR_SPI_CTRL, rdata);
        check32("SPI_CTRL start self-clear", rdata, 32'h0000_0800);

        wait_spi_done(rdata);

        if (rdata[0] !== 1'b0) begin
            $error("[FAIL] SPI busy still high after done. status=0x%08h", rdata);
        end else begin
            $display("[PASS] SPI busy low after done");
        end

        axi_read(ADDR_SPI_RXDATA, rdata);
        check32("SPI_RXDATA", rdata, 32'h0000_00A5);

        if (spi_slave_rx_data !== 8'h3C) begin
            $error("[FAIL] SPI slave RX actual=0x%02h expected=0x3C", spi_slave_rx_data);
        end else begin
            $display("[PASS] SPI slave RX = 0x%02h", spi_slave_rx_data);
        end

        axi_write(ADDR_SPI_CTRL, 32'h0000_0808);  // clear latched done
        axi_read(ADDR_SPI_STATUS, rdata);
        check32("SPI_STATUS after clear", rdata, 32'h0000_0000);

        $display("========================================");
        $display(" AXI Peripheral Register Bank TB Done");
        $display("========================================");

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule
