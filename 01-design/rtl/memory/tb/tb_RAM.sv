`timescale 1ns / 1ps

class transaction;
    rand bit we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic [7:0] rdata;

    constraint wr_ratio {
        we dist {
            1 := 70,
            0 := 30
        };
    }

    function void display(string tag);
        $display("[%0t][%s] we=%0b addr=%0h wdata=%0h rdata=%0h", $time, tag, we, addr, wdata,
                 rdata);
    endfunction
endclass


interface ram_intf (
    input logic clk
);
    logic we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface


class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbx;

    bit done = 0;

    function new(mailbox#(transaction) gen2drv_mbx);
        this.gen2drv_mbx = gen2drv_mbx;
    endfunction

    task run();

        for (int i = 0; i < 10; i++) begin
            tr = new();
            assert (tr.randomize());
            tr.we   = 1;
            tr.addr = i;
            gen2drv_mbx.put(tr);
        end

        for (int i = 0; i < 10; i++) begin
            tr = new();
            assert (tr.randomize());
            tr.we   = 0;
            tr.addr = i;
            gen2drv_mbx.put(tr);
        end

        done = 1;
    endtask
endclass


class driver;
    transaction tr;

    virtual ram_intf ram_vif;
    mailbox #(transaction) gen2drv_mbx;

    function new(mailbox#(transaction) gen2drv_mbx, virtual ram_intf ram_vif);
        this.gen2drv_mbx = gen2drv_mbx;
        this.ram_vif     = ram_vif;
    endfunction

    task run();

        ram_vif.we    <= 0;
        ram_vif.addr  <= 0;
        ram_vif.wdata <= 0;

        forever begin

            gen2drv_mbx.get(tr);

            @(negedge ram_vif.clk);

            ram_vif.we    <= tr.we;
            ram_vif.addr  <= tr.addr;
            ram_vif.wdata <= tr.wdata;

            tr.display("DRV");

        end
    endtask
endclass


class monitor;

    virtual ram_intf ram_vif;
    mailbox #(transaction) mon2scb_mbx;

    transaction tr;

    function new(virtual ram_intf ram_vif, mailbox#(transaction) mon2scb_mbx);
        this.ram_vif     = ram_vif;
        this.mon2scb_mbx = mon2scb_mbx;
    endfunction

    task run();

        forever begin

            @(posedge ram_vif.clk);
            #1;

            tr = new();

            tr.we    = ram_vif.we;
            tr.addr  = ram_vif.addr;
            tr.wdata = ram_vif.wdata;
            tr.rdata = ram_vif.rdata;

            tr.display("MON");

            mon2scb_mbx.put(tr);

        end
    endtask

endclass


class scoreboard;

    mailbox #(transaction) mon2scb_mbx;
    transaction tr;

    logic [7:0] sc_mem[logic [7:0]];

    int match_cnt = 0;
    int error_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbx);
        this.mon2scb_mbx = mon2scb_mbx;
    endfunction

    task run();

        logic [7:0] expected_data;

        forever begin

            mon2scb_mbx.get(tr);

            if (tr.we) begin

                sc_mem[tr.addr] = tr.wdata;

                $display("[SB_WRITE] addr=%0h data=%0h", tr.addr, tr.wdata);

            end else begin

                if (sc_mem.exists(tr.addr)) begin

                    expected_data = sc_mem[tr.addr];

                    if (tr.rdata === expected_data) begin

                        match_cnt++;

                        $display("[SB_MATCH] addr=%0h exp=%0h act=%0h", tr.addr, expected_data,
                                 tr.rdata);

                    end else begin

                        error_cnt++;

                        $error("[SB_FAIL] addr=%0h exp=%0h act=%0h", tr.addr, expected_data,
                               tr.rdata);

                    end
                end
            end
        end
    endtask

endclass


class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbx;
    mailbox #(transaction) mon2scb_mbx;

    virtual ram_intf ram_vif;

    function new(virtual ram_intf ram_vif);

        this.ram_vif = ram_vif;

        gen2drv_mbx = new();
        mon2scb_mbx = new();

        gen = new(gen2drv_mbx);
        drv = new(gen2drv_mbx, ram_vif);
        mon = new(ram_vif, mon2scb_mbx);
        scb = new(mon2scb_mbx);

    endfunction

    task test();

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

        // Wait until exactly 10 read transactions are verified in the scoreboard!
        wait (scb.match_cnt + scb.error_cnt == 10);

        $display("");
        $display("=================================");
        $display("      VERIFICATION REPORT");
        $display("=================================");
        $display("MATCH COUNT : %0d", scb.match_cnt);
        $display("ERROR COUNT : %0d", scb.error_cnt);
        $display("=================================");

    endtask

endclass


module tb_RAM ();

    logic clk;

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    ram_intf ram_if (clk);

    ram dut (
        .clk  (ram_if.clk),
        .we   (ram_if.we),
        .addr (ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    environment env;

    initial begin


        env = new(ram_if);

        env.test();

        $finish;

    end

endmodule
