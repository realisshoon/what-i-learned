`timescale 1ns / 1ps

module tb_myip_axi_slave;
    // AXI slave interface parameters
    parameter integer C_S00_AXI_DATA_WIDTH = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH = 4;

    // AXI slave bus interface
    logic                                s00_axi_aclk;
    logic                                s00_axi_aresetn;

    logic [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [                         2:0] s00_axi_awprot;
    logic                                s00_axi_awvalid;
    logic                                s00_axi_awready;

    logic [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic                                s00_axi_wvalid;
    logic                                s00_axi_wready;

    logic [                         1:0] s00_axi_bresp;
    logic                                s00_axi_bvalid;
    logic                                s00_axi_bready;

    logic [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [                         2:0] s00_axi_arprot;
    logic                                s00_axi_arvalid;
    logic                                s00_axi_arready;

    logic [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [                         1:0] s00_axi_rresp;
    logic                                s00_axi_rvalid;
    logic                                s00_axi_rready;



    myip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) dut (
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),

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


    task axi_write(input [C_S00_AXI_ADDR_WIDTH-1:0] addr, input [C_S00_AXI_DATA_WIDTH-1:0] data);
        begin
            @(posedge s00_axi_aclk);

            s00_axi_awaddr  <= addr;
            s00_axi_awvalid <= 1'b1;

            s00_axi_wdata   <= data;
            s00_axi_wstrb   <= 4'b1111;
            s00_axi_wvalid  <= 1'b1;

            s00_axi_bready  <= 1'b1;

            // Xilinx template은 보통 AWVALID와 WVALID가 같이 들어올 때 ready를 올림
            wait (s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);

            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;

            wait (s00_axi_bvalid);
            @(posedge s00_axi_aclk);

            $display("[WRITE] addr=%h data=%h bresp=%b", addr, data, s00_axi_bresp);

            s00_axi_bready <= 1'b0;
            @(posedge s00_axi_aclk);
        end
    endtask

    task axi_read(input [C_S00_AXI_ADDR_WIDTH-1:0] addr);
        begin
            @(posedge s00_axi_aclk);

            s00_axi_araddr  <= addr;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            wait (s00_axi_arready);
            @(posedge s00_axi_aclk);

            s00_axi_arvalid <= 1'b0;

            wait (s00_axi_rvalid);
            @(posedge s00_axi_aclk);

            $display("[READ ] addr=%h data=%h rresp=%b", addr, s00_axi_rdata, s00_axi_rresp);

            s00_axi_rready <= 1'b0;
            @(posedge s00_axi_aclk);
        end
    endtask





    initial begin
        s00_axi_aclk = 1'b0;
        forever #5 s00_axi_aclk = ~s00_axi_aclk;  // 100MHz clock
    end


    initial begin
        // 초기값
        s00_axi_aresetn = 1'b0;

        s00_axi_awaddr  = '0;
        s00_axi_awprot  = 3'b000;
        s00_axi_awvalid = 1'b0;

        s00_axi_wdata   = '0;
        s00_axi_wstrb   = 4'b1111;
        s00_axi_wvalid  = 1'b0;

        s00_axi_bready  = 1'b0;

        s00_axi_araddr  = '0;
        s00_axi_arprot  = 3'b000;
        s00_axi_arvalid = 1'b0;

        s00_axi_rready  = 1'b0;

        // reset 유지
        repeat (10) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1'b1;
        repeat (2) @(posedge s00_axi_aclk);

        // Test Sequence
        axi_write(4'h0, 32'h1111_1111);
        axi_read(4'h0);

        axi_write(4'h4, 32'h2222_2222);
        axi_read(4'h4);

        axi_write(4'h8, 32'h3333_3333);
        axi_read(4'h8);

        axi_write(4'hC, 32'h4444_4444);
        axi_read(4'hC);

        repeat (10) @(posedge s00_axi_aclk);
        $finish;
    end





endmodule
