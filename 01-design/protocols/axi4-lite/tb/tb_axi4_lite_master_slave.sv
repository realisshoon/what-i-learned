`timescale 1ns / 1ps

module tb_axi4_lite ();
    logic        ACLK;
    logic        ARESET_n;

    // AW channel
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    // W channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;

    // B channel
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;

    // AR channel
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        AREADY;  // 나중에 ARREADY로 이름 바꾸는 것 추천

    // R channel
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;

    // internal signals
    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;

    axi4_lite_master dut_master (.*);
    axi4_lite_slave dut_slave (.*);

    typedef enum logic {
        STOP  = 0,
        START = 1
    } e_state_t;

    e_state_t n_state, c_state;

    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    task automatic axi_write(logic [31:0] address, logic [31:0] data);
        addr = address;
        wdata = data;
        write = 1'b1;
        transfer = 1'b1;
        @(posedge ACLK);
        wait (ready);
        @(posedge ACLK);
        $display("[%0t] AXI WRITE = Addr= %0h, WDATA= %0h", $time, addr, wdata);
    endtask  //automatic


    initial begin
        ARESET_n = 0;
        repeat (3) @(posedge ACLK);
        ARESET_n = 1;

        axi_write(32'h00, 32'h111111111);
        axi_write(32'h00, 32'h222222222);
        axi_write(32'h00, 32'h333333333);
        axi_write(32'h00, 32'h444444444);
    end


endmodule
