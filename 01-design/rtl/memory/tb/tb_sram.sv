`timescale 1ns / 1ps

// 1. Interface
interface sram_interface;
    logic       clk;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface

// 2. Transaction
class transaction;
    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    bit      [7:0] rdata;

    constraint addr_range {
        addr < 10;
    }

    function void debug_print(string name);
        $display(
            "[%s] Time: %0t | we: %0d | addr: %0d | wdata: %0d | rdata: %0d",
            name, $time, we, addr, wdata, rdata);
    endfunction
endclass

// 3. Generator
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new;
            //assertion
            assert (tr.randomize())
            else $error("[GEN] tr.randomize() error! at time %t", $time);
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask
endclass : generator

// 4. Driver
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual sram_interface sram_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual sram_interface sram_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.sram_vif = sram_vif;
    endfunction
    task preset();
        sram_vif.addr = 0;
        sram_vif.wdata = 0;
        sram_vif.we = 0;
        @(posedge sram_vif.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge sram_vif.clk);
            #1;
            sram_vif.addr = tr.addr;
            sram_vif.wdata = tr.wdata;
            sram_vif.we = tr.we;
        end
    endtask
endclass

// 5. Monitor
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual sram_interface sram_vif;

    function new(virtual sram_interface sram_vif,
                 mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.sram_vif = sram_vif;
    endfunction

    task run();
        forever begin
            @(negedge sram_vif.clk);
            // #1;
            tr = new();
            tr.addr = sram_vif.addr;
            tr.wdata = sram_vif.wdata;
            tr.we    = sram_vif.we;
            tr.rdata = sram_vif.rdata;
            tr.debug_print("MON");
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// 6. Scoreboard
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;
    int total_cnt = 0, pass_cnt = 0, fail_cnt=0;

    byte mem[256];

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            //pass fail
            if(tr.we) begin //write
                mem[tr.addr] = tr.wdata;
            end else begin  // read
                if(tr.rdata == mem[tr.addr]) begin
                    $display("%t : PASS ",$time);
                    pass_cnt ++;
                end else begin
                    $display("%t : Fail addr = %d, rdata = %d, compare data = %d ",$time,tr.addr,
                    tr.rdata, mem[tr.addr]);
                    fail_cnt ++;
                end
            end
            ->event_gen_next;
        end
    endtask

endclass

// 7. Environment
class environment;
    transaction         tr;
    generator           gen;
    driver              drv;
    monitor             mon;
    scoreboard          scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;

    virtual sram_interface sram_vif;

    function new(virtual sram_interface sram_vif);
        this.sram_vif = sram_vif;
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, sram_vif);
        mon = new(sram_vif, mon2scb_mbox);
        scb = new(mon2scb_mbox, event_gen_next);
    endfunction


    task run();
        drv.preset();
        fork
            gen.run(20);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("env run task end");
        $display("________________");
        $display("** SRAM IP Verification");
        $display("** total test num = %2d **",scb.total_cnt);
        $display("** pass test num = %2d **",scb.pass_cnt);
        $display("** fail test num = %2d **",scb.fail_cnt);
        $stop;
    endtask
endclass

// 8. Top Module
module tb_sram ();
    logic clk;
    environment env;

    sram_interface sram_if ();

    assign sram_if.clk = clk;

    ram_ip dut (
        .clk  (sram_if.clk),
        .addr (sram_if.addr),
        .wdata(sram_if.wdata),
        .we   (sram_if.we),
        .rdata(sram_if.rdata)
    );


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(sram_if);
        env.run();
    end
endmodule
