
`timescale 1 ns / 1 ps

module axi_peripheral_v1_0_S00_AXI #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 7
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

    output wire       spi_start,
    output wire [7:0] spi_tx_data,
    output wire [7:0] spi_clk_div,
    output wire       spi_cpol,
    output wire       spi_cpha,
    input  wire       spi_busy,
    input  wire       spi_done,
    input  wire [7:0] spi_rx_data,
    input  wire       spi_error,

    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 4;

    // ------------------------------------------------------------
    // Register Index
    // AXI address offset = index * 4
    // ------------------------------------------------------------
    localparam [4:0] REG_SYS_CTRL = 5'h00;  // 0x00
    localparam [4:0] REG_SYS_STATUS = 5'h01;  // 0x04
    localparam [4:0] REG_GPIO_OUT = 5'h02;  // 0x08
    localparam [4:0] REG_GPIO_IN = 5'h03;  // 0x0C

    localparam [4:0] REG_TIMER_CTRL = 5'h04;  // 0x10
    localparam [4:0] REG_TIMER_STATUS = 5'h05;  // 0x14
    localparam [4:0] REG_TIMER_COMPARE = 5'h06;  // 0x18
    localparam [4:0] REG_TIMER_COUNT = 5'h07;  // 0x1C

    localparam [4:0] REG_SPI_CTRL = 5'h08;  // 0x20
    localparam [4:0] REG_SPI_STATUS = 5'h09;  // 0x24
    localparam [4:0] REG_SPI_TXDATA = 5'h0A;  // 0x28
    localparam [4:0] REG_SPI_RXDATA = 5'h0B;  // 0x2C

    localparam [4:0] REG_I2C_CTRL = 5'h0C;  // 0x30
    localparam [4:0] REG_I2C_STATUS = 5'h0D;  // 0x34
    localparam [4:0] REG_I2C_DEV_ADDR = 5'h0E;  // 0x38
    localparam [4:0] REG_I2C_TXDATA = 5'h0F;  // 0x3C
    localparam [4:0] REG_I2C_RXDATA = 5'h10;  // 0x40

    localparam [4:0] REG_LCD_CTRL = 5'h11;  // 0x44
    localparam [4:0] REG_LCD_STATUS = 5'h12;  // 0x48
    localparam [4:0] REG_LCD_CHAR = 5'h13;  // 0x4C
    localparam [4:0] REG_LCD_POS = 5'h14;  // 0x50

    localparam [4:0] REG_RESERVED0 = 5'h15;  // 0x54
    localparam [4:0] REG_RESERVED1 = 5'h16;  // 0x58
    localparam [4:0] REG_RESERVED2 = 5'h17;  // 0x5C
    localparam [4:0] REG_RESERVED3 = 5'h18;  // 0x60

    localparam [4:0] REG_AUTO_CTRL = 5'h19;  // 0x64
    localparam [4:0] REG_AUTO_STATUS = 5'h1A;  // 0x68
    localparam [4:0] REG_RESULT_DATA = 5'h1B;  // 0x6C
    localparam [4:0] REG_ELAPSED_TIME = 5'h1C;  // 0x70
    localparam [4:0] REG_ERROR_CODE = 5'h1D;  // 0x74
    localparam [4:0] REG_DEBUG0 = 5'h1E;  // 0x78
    localparam [4:0] REG_DEBUG1 = 5'h1F;  // 0x7C

    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 32
    // ------------------------------------------------------------

    // ------------------------------------------------------------
    // Register Map
    // ------------------------------------------------------------
    // Offset | Register      | Access | Description
    // 0x00   | SYS_CTRL      | R/W    | bit[0] soft_reset, bit[1] demo_start, bit[2] clear_status
    // 0x04   | SYS_STATUS    | R/O    | bit[0] busy, bit[1] done, bit[2] error
    // 0x08   | GPIO_OUT      | R/W    | bit[7:0] led_out, bit[8] board2_reset_n, bit[9] board2_start
    // 0x0C   | GPIO_IN       | R/O    | bit[7:0] switch_in, bit[8] board2_ready, bit[9] board2_done
    // 0x10   | TIMER_CTRL    | R/W    | bit[0] enable, bit[1] clear, bit[2] periodic
    // 0x14   | TIMER_STATUS  | R/O    | bit[0] tick, bit[1] timeout, bit[2] busy
    // 0x18   | TIMER_COMPARE | R/W    | timer compare value
    // 0x1C   | TIMER_COUNT   | R/O    | current timer count
    // 0x20   | SPI_CTRL      | R/W    | bit[0] start, bit[1] cpol, bit[2] cpha
    // 0x24   | SPI_STATUS    | R/O    | bit[0] busy, bit[1] done, bit[2] error
    // 0x28   | SPI_TXDATA    | R/W    | SPI transmit data
    // 0x2C   | SPI_RXDATA    | R/O    | SPI received data
    // 0x30   | I2C_CTRL      | R/W    | bit[0] start, bit[1] stop, bit[2] rw
    // 0x34   | I2C_STATUS    | R/O    | bit[0] busy, bit[1] done, bit[2] ack_error
    // 0x38   | I2C_DEV_ADDR  | R/W    | I2C device address
    // 0x3C   | I2C_TXDATA    | R/W    | I2C transmit data
    // 0x40   | I2C_RXDATA    | R/O    | I2C received data
    // 0x44   | LCD_CTRL      | R/W    | bit[0] init, bit[1] clear, bit[2] write_char
    // 0x48   | LCD_STATUS    | R/O    | bit[0] busy, bit[1] done, bit[2] error
    // 0x4C   | LCD_CHAR      | R/W    | LCD ASCII character
    // 0x50   | LCD_POS       | R/W    | bit[3:0] column, bit[4] line
    // 0x54   | RESERVED0     | R/W    | reserved for future use
    // 0x58   | RESERVED1     | R/W    | reserved for future use
    // 0x5C   | RESERVED2     | R/W    | reserved for future use
    // 0x60   | RESERVED3     | R/W    | reserved for future use
    // 0x64   | AUTO_CTRL     | R/W    | bit[0] auto_start, bit[1] auto_stop
    // 0x68   | AUTO_STATUS   | R/O    | bit[0] auto_busy, bit[1] auto_done, bit[2] auto_error
    // 0x6C   | RESULT_DATA   | R/O    | final result data
    // 0x70   | ELAPSED_TIME  | R/O    | elapsed time count
    // 0x74   | ERROR_CODE    | R/O    | error code
    // 0x78   | DEBUG0        | R/W    | debug register 0
    // 0x7C   | DEBUG1        | R/W    | debug register 1


    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg9;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg10;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg11;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg12;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg13;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg14;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg15;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg16;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg17;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg18;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg19;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg20;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg21;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg22;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg23;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg24;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg25;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg26;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg27;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg28;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg29;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg30;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg31;
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    reg aw_en;

    wire [4:0] wr_addr_index;
    wire [4:0] rd_addr_index;
    wire       spi_clear_status;

    assign wr_addr_index = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
    assign rd_addr_index = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
    // I/O Connections assignments

    function [C_S_AXI_DATA_WIDTH-1:0] apply_wstrb;
        input [C_S_AXI_DATA_WIDTH-1:0] old_data;
        input [C_S_AXI_DATA_WIDTH-1:0] new_data;
        input [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb;
        integer i;
        begin
            apply_wstrb = old_data;
            for (i = 0; i <= (C_S_AXI_DATA_WIDTH / 8) - 1; i = i + 1) begin
                if (wstrb[i] == 1'b1) begin
                    apply_wstrb[(i*8)+:8] = new_data[(i*8)+:8];
                end
            end
        end
    endfunction


    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;
    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.

    // ------------------------------------------------------------
    // Hardware-driven register values
    // R/O registers are read from these wires.
    // Later, connect these wires to Timer/SPI/I2C/LCD cores.
    // ------------------------------------------------------------
    wire [31:0] sys_status_hw;
    wire [31:0] gpio_in_hw;
    wire [31:0] timer_status_hw;
    wire [31:0] timer_count_hw;
    wire [31:0] spi_status_hw;
    wire [31:0] spi_rxdata_hw;
    wire [31:0] i2c_status_hw;
    wire [31:0] i2c_rxdata_hw;
    wire [31:0] lcd_status_hw;
    wire [31:0] auto_status_hw;
    wire [31:0] result_data_hw;
    wire [31:0] elapsed_time_hw;
    wire [31:0] error_code_hw;

    assign sys_status_hw = 32'd0;

    assign gpio_in_hw = {
        21'd0,
        board2_error,  // bit[10]
        board2_done,  // bit[9]
        board2_ready,  // bit[8]
        gpio_sw  // bit[7:0]
    };

    assign timer_status_hw = 32'd0;
    assign timer_count_hw = 32'd0;

    reg       spi_done_latched;
    reg [7:0] spi_rx_data_latched;

    assign spi_start =
        slv_reg_wren &&
        (wr_addr_index == REG_SPI_CTRL) &&
        S_AXI_WSTRB[0] &&
        S_AXI_WDATA[0] &&
        !spi_busy;

    assign spi_clear_status =
        slv_reg_wren &&
        (wr_addr_index == REG_SPI_CTRL) &&
        S_AXI_WSTRB[0] &&
        S_AXI_WDATA[3];

    assign spi_tx_data = slv_reg10[7:0];
    assign spi_clk_div = (slv_reg8[15:8] == 8'd0) ? 8'd4 : slv_reg8[15:8];
    assign spi_cpol    = slv_reg8[1];
    assign spi_cpha    = slv_reg8[2];

    assign spi_status_hw = {
        29'd0,
        spi_error,         // bit[2]
        spi_done_latched,  // bit[1]
        spi_busy           // bit[0]
    };

    assign spi_rxdata_hw = {24'd0, spi_rx_data_latched};

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            spi_done_latched   <= 1'b0;
            spi_rx_data_latched <= 8'd0;
        end else begin
            if (spi_start || spi_clear_status) begin
                spi_done_latched <= 1'b0;
            end

            if (spi_done) begin
                spi_done_latched   <= 1'b1;
                spi_rx_data_latched <= spi_rx_data;
            end
        end
    end

    assign i2c_status_hw = 32'd0;
    assign i2c_rxdata_hw = 32'd0;

    assign lcd_status_hw = 32'd0;

    assign auto_status_hw = 32'd0;
    assign result_data_hw = 32'd0;
    assign elapsed_time_hw = 32'd0;
    assign error_code_hw = 32'd0;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    // de-asserted when reset is low. 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                // slave is ready to accept write data when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end




    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0  <= 0;
            slv_reg1  <= 0;
            slv_reg2  <= 0;
            slv_reg3  <= 0;
            slv_reg4  <= 0;
            slv_reg5  <= 0;
            slv_reg6  <= 0;
            slv_reg7  <= 0;
            slv_reg8  <= 0;
            slv_reg9  <= 0;
            slv_reg10 <= 0;
            slv_reg11 <= 0;
            slv_reg12 <= 0;
            slv_reg13 <= 0;
            slv_reg14 <= 0;
            slv_reg15 <= 0;
            slv_reg16 <= 0;
            slv_reg17 <= 0;
            slv_reg18 <= 0;
            slv_reg19 <= 0;
            slv_reg20 <= 0;
            slv_reg21 <= 0;
            slv_reg22 <= 0;
            slv_reg23 <= 0;
            slv_reg24 <= 0;
            slv_reg25 <= 0;
            slv_reg26 <= 0;
            slv_reg27 <= 0;
            slv_reg28 <= 0;
            slv_reg29 <= 0;
            slv_reg30 <= 0;
            slv_reg31 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (wr_addr_index)
                    // ----------------------------------------------------
                    // R/W registers
                    // ----------------------------------------------------
                    REG_SYS_CTRL: slv_reg0 <= apply_wstrb(slv_reg0, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_GPIO_OUT: slv_reg2 <= apply_wstrb(slv_reg2, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_TIMER_CTRL: slv_reg4 <= apply_wstrb(slv_reg4, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_TIMER_COMPARE: slv_reg6 <= apply_wstrb(slv_reg6, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_SPI_CTRL: slv_reg8 <= apply_wstrb(slv_reg8, S_AXI_WDATA, S_AXI_WSTRB) & 32'hFFFF_FFF6;
                    REG_SPI_TXDATA: slv_reg10 <= apply_wstrb(slv_reg10, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_I2C_CTRL: slv_reg12 <= apply_wstrb(slv_reg12, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_I2C_DEV_ADDR: slv_reg14 <= apply_wstrb(slv_reg14, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_I2C_TXDATA: slv_reg15 <= apply_wstrb(slv_reg15, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_LCD_CTRL: slv_reg17 <= apply_wstrb(slv_reg17, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_LCD_CHAR: slv_reg19 <= apply_wstrb(slv_reg19, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_LCD_POS: slv_reg20 <= apply_wstrb(slv_reg20, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_RESERVED0: slv_reg21 <= apply_wstrb(slv_reg21, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_RESERVED1: slv_reg22 <= apply_wstrb(slv_reg22, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_RESERVED2: slv_reg23 <= apply_wstrb(slv_reg23, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_RESERVED3: slv_reg24 <= apply_wstrb(slv_reg24, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_AUTO_CTRL: slv_reg25 <= apply_wstrb(slv_reg25, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_DEBUG0: slv_reg30 <= apply_wstrb(slv_reg30, S_AXI_WDATA, S_AXI_WSTRB);
                    REG_DEBUG1: slv_reg31 <= apply_wstrb(slv_reg31, S_AXI_WDATA, S_AXI_WSTRB);
                    // ----------------------------------------------------
                    // R/O registers: write ignored
                    // ----------------------------------------------------
                    default: begin
                        // Do nothing
                    end
                endcase
            end
        end
    end

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
    // This marks the acceptance of address and indicates the status of 
    // write transaction.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;  // 'OKAY' response 
            end                   // work error responses in future
	      else
	        begin
                if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when S_AXI_ARVALID is 
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1'b1;
                // Read address latching
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                // Valid read data is available at the read data bus
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // 'OKAY' response
            end else if (axi_rvalid && S_AXI_RREADY) begin
                // Read data is accepted by the master
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        // Address decoding for reading registers
        case (rd_addr_index)
            REG_SYS_CTRL:   reg_data_out = slv_reg0;
            REG_SYS_STATUS: reg_data_out = sys_status_hw;

            REG_GPIO_OUT: reg_data_out = slv_reg2;
            REG_GPIO_IN:  reg_data_out = gpio_in_hw;

            REG_TIMER_CTRL:    reg_data_out = slv_reg4;
            REG_TIMER_STATUS:  reg_data_out = timer_status_hw;
            REG_TIMER_COMPARE: reg_data_out = slv_reg6;
            REG_TIMER_COUNT:   reg_data_out = timer_count_hw;

            REG_SPI_CTRL:   reg_data_out = slv_reg8;
            REG_SPI_STATUS: reg_data_out = spi_status_hw;
            REG_SPI_TXDATA: reg_data_out = slv_reg10;
            REG_SPI_RXDATA: reg_data_out = spi_rxdata_hw;

            REG_I2C_CTRL:     reg_data_out = slv_reg12;
            REG_I2C_STATUS:   reg_data_out = i2c_status_hw;
            REG_I2C_DEV_ADDR: reg_data_out = slv_reg14;
            REG_I2C_TXDATA:   reg_data_out = slv_reg15;
            REG_I2C_RXDATA:   reg_data_out = i2c_rxdata_hw;

            REG_LCD_CTRL:   reg_data_out = slv_reg17;
            REG_LCD_STATUS: reg_data_out = lcd_status_hw;
            REG_LCD_CHAR:   reg_data_out = slv_reg19;
            REG_LCD_POS:    reg_data_out = slv_reg20;

            REG_RESERVED0: reg_data_out = slv_reg21;
            REG_RESERVED1: reg_data_out = slv_reg22;
            REG_RESERVED2: reg_data_out = slv_reg23;
            REG_RESERVED3: reg_data_out = slv_reg24;

            REG_AUTO_CTRL:   reg_data_out = slv_reg25;
            REG_AUTO_STATUS: reg_data_out = auto_status_hw;

            REG_RESULT_DATA:  reg_data_out = result_data_hw;
            REG_ELAPSED_TIME: reg_data_out = elapsed_time_hw;
            REG_ERROR_CODE:   reg_data_out = error_code_hw;

            REG_DEBUG0: reg_data_out = slv_reg30;
            REG_DEBUG1: reg_data_out = slv_reg31;

            default: reg_data_out = 32'd0;
        endcase
    end

    // Output register or memory read data
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            // When there is a valid read address (S_AXI_ARVALID) with 
            // acceptance of read address by the slave (axi_arready), 
            // output the read dada 
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;  // register read data
            end
        end
    end

    // Add user logic here
    // ------------------------------------------------------------
    // GPIO output mapping
    // GPIO_OUT register = slv_reg2
    // ------------------------------------------------------------
    assign gpio_led       = slv_reg2[7:0];
    assign board2_reset_n = slv_reg2[8];
    assign board2_start   = slv_reg2[9];
    assign board2_mode    = slv_reg2[11:10];
    // User logic ends

endmodule
