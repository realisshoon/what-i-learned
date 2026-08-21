`timescale 1ns / 1ps

module tb_axi_timer ();

    parameter integer C_S00_AXI_DATA_WIDTH = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH = 4;

    logic                                  clk;
    logic                                  reset_n;

    logic                                  w_loop;
    logic                                  tx;
    logic                                  rx;
    logic                                  intr;
    logic                                  s00_axi_aclk;
    logic                                  s00_axi_aresetn;
    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    logic [                         2 : 0] s00_axi_awprot;
    logic                                  s00_axi_awvalid;
    logic                                  s00_axi_awready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    logic                                  s00_axi_wvalid;
    logic                                  s00_axi_wready;
    logic [                         1 : 0] s00_axi_bresp;
    logic                                  s00_axi_bvalid;
    logic                                  s00_axi_bready;
    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    logic [                         2 : 0] s00_axi_arprot;
    logic                                  s00_axi_arvalid;
    logic                                  s00_axi_arready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    logic [                         1 : 0] s00_axi_rresp;
    logic                                  s00_axi_rvalid;
    logic                                  s00_axi_rready;

    assign s00_axi_aclk = clk;
    assign s00_axi_aresetn = reset_n;

    axi_uart_v1_0 dut (
        .*,
        .tx(w_loop),
        .rx(w_loop)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    localparam UART_SR_ADDR = 32'h0000_0000;
    localparam UART_TDR_ADDR = 32'h0000_0004;
    localparam UART_RDR_ADDR = 32'h0000_0008;
    localparam UART_CR_ADDR = 32'h0000_000c;

    logic [31:0] SR, TDR, RDR, CR;

    task automatic AXI_WriteData(logic [31:0] addr, logic [31:0] data);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;
        @(posedge clk);
        wait (s00_axi_awready & s00_axi_wready) @(posedge clk);
        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;
        @(posedge clk);
        wait (s00_axi_bvalid);
        @(posedge clk);
        s00_axi_bready <= 1'b0;
        @(posedge clk);
    endtask

    // task automatic AXI_ReadData(input logic [31:0] addr, output logic [31:0] rdata);
    //     s00_axi_araddr  <= addr;
    //     s00_axi_arvalid <= 1'b1;
    //     s00_axi_rready  <= 1'b1;
    //     @(posedge clk);
    //     wait (s00_axi_arready);
    //     @(posedge clk);
    //     s00_axi_arvalid <= 1'b0;
    //     wait (s00_axi_arready);
    //     @(posedge clk);
    //     s00_axi_rready <= 1'b0;
    //     rdata = s00_axi_rdata;
    //     @(posedge clk);

    // endtask

    task automatic AXI_ReadData(input logic [31:0] addr, output logic [31:0] rdata);
        begin
            @(posedge clk);
            s00_axi_araddr  <= addr[C_S00_AXI_ADDR_WIDTH-1:0];
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            // Read address handshake 대기
            do begin
                @(posedge clk);
            end while (!(s00_axi_arvalid && s00_axi_arready));

            s00_axi_arvalid <= 1'b0;

            // Read data valid 대기
            do begin
                @(posedge clk);
            end while (!(s00_axi_rvalid && s00_axi_rready));

            rdata = s00_axi_rdata;

            @(posedge clk);
            s00_axi_rready <= 1'b0;

            $display("[AXI READ] addr=%h rdata=%h time=%0t", addr, rdata, $time);
        end
    endtask

    initial begin
        reset_n = 0;
        CR = 0;
        SR = 0;
        TDR = 0;
        RDR = 0;
        repeat (5) @(posedge clk);
        reset_n = 1;
        @(posedge clk);

        CR |= (1 << 0);  // interrupt enable
        AXI_WriteData(UART_CR_ADDR, CR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'haa;
        AXI_WriteData(UART_TDR_ADDR, TDR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        AXI_ReadData(UART_RDR_ADDR, RDR);

        TDR = 8'h55;
        AXI_WriteData(UART_TDR_ADDR, TDR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        AXI_ReadData(UART_RDR_ADDR, RDR);


        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h12;
        AXI_WriteData(UART_TDR_ADDR, TDR);


        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        AXI_ReadData(UART_RDR_ADDR, RDR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h34;
        AXI_WriteData(UART_TDR_ADDR, TDR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        AXI_ReadData(UART_RDR_ADDR, RDR);


        // Interrupt
        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h34;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(UART_RDR_ADDR, RDR);
        @(posedge clk);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h22;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        wait (intr);
        AXI_ReadData(UART_RDR_ADDR, RDR);
        @(posedge clk);



        // wait (intr);
        @(posedge clk);

        repeat (5) @(posedge clk);

        // AXI_ReadData(UART_RDR_ADDR);

        #1000;
        $stop;
    end

endmodule
