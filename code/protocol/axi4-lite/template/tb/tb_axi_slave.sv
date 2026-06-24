`timescale 1ns / 1ps

module tb_axi_slave ();
    parameter integer C_S00_AXI_DATA_WIDTH = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH = 4;

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
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] rdata_r;
    logic [                         1 : 0] s00_axi_rresp;
    logic                                  s00_axi_rvalid;
    logic                                  s00_axi_rready;
    // Instantiation of Axi Bus Interface S00_AXI
    axi_template_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) dut (
        .*
    );


    task automatic axi_write(logic [31:0] addr, logic [31:0] data);
        @(posedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;
        s00_axi_bready  <= 1'b1;
        wait (s00_axi_awready & s00_axi_wready);
        @(posedge s00_axi_aclk);
        s00_axi_wvalid  <= 1'b0;
        s00_axi_awvalid <= 1'b0;

        wait (s00_axi_bvalid);
        @(posedge s00_axi_aclk);
        s00_axi_bready <= 1'b0;
        $display("[%0t] WRITE : addr= 0x%0h, wdata : 0x%0h", $time, addr, data);
    endtask  //automatic

    task automatic axi_read(logic [31:0] addr);
        @(posedge s00_axi_aclk);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;
        wait (s00_axi_arready);
        @(posedge s00_axi_aclk);
        s00_axi_arvalid <= 1'b0;

        wait (s00_axi_rvalid);
        @(posedge s00_axi_aclk);
        rdata_r        <= s00_axi_rdata;
        s00_axi_rready <= 1'b0;

        @(posedge s00_axi_aclk);
        $display("[%0t] READ : addr= 0x%0h, rdata : 0x%0h", $time, addr, s00_axi_rdata);
    endtask  //automatic



    always #5 s00_axi_aclk = ~s00_axi_aclk;

    initial begin
        s00_axi_aclk    = 0;
        s00_axi_aresetn = 0;
        s00_axi_awaddr  = 0;
        s00_axi_awprot  = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 0;
        s00_axi_wvalid  = 0;
        s00_axi_bready  = 0;
        s00_axi_araddr  = 0;
        s00_axi_arprot  = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 0;
        repeat (3) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1;
        repeat (2) @(posedge s00_axi_aclk);
        axi_write(32'h00000000, 32'hDEADBEEF);
        axi_write(32'h00000004, 32'hCAFEBABE);
        axi_write(32'h00000008, 32'h12345678);
        axi_write(32'h0000000C, 32'hAAAABBBB);
        repeat (2) @(posedge s00_axi_aclk);
        axi_read(32'h00000000);
        axi_read(32'h00000004);
        axi_read(32'h00000008);
        axi_read(32'h0000000C);
        #100;
        $finish;

    end

endmodule
