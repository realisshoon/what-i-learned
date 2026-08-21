interface ram_if (
    input logic clk
);

    logic       we;
    logic [7:0] wdata;
    logic [7:0] addr;
    logic [7:0] rdata;


    // driver 입장
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output we;
        output addr;
        output wdata;
        input rdata;
    endclocking

    // monitor 입장에서
    clocking mon_cb @(posedge clk);
        default input #1step;
        input we;
        input addr;
        input wdata;
        input rdata;
    endclocking

    modport DRV(clocking drv_cb, input clk);
    modport MON(clocking mon_cb, input clk);

endinterface  //ram_if
