`timescale 1ns / 1ps

// 1. Interface
interface fifo_interface;
    logic       clk;
    logic       rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
endinterface

// 2. Transaction
class transaction;
    rand bit [7:0] push_data;
    rand bit       push;
    rand bit       pop;
    bit      [7:0] pop_data;
    bit            full;
    bit            empty;

    // int            test_mode;

    function void debug_print(string name);
        $display(
            "[%s] Time: %0t | push: %0d | push_data: %0d | pop: %0d | pop_data: %0d | full: %0d | empty: %0d"
            , name, $time, push, push_data, pop, pop_data, full, empty);
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
    event event_gen_next;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_vif, event event_gen_next);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_vif = fifo_vif;
        this.event_gen_next = event_gen_next;
    endfunction
    task preset();
        fifo_vif.rst       = 1;
        fifo_vif.push_data = 0;
        fifo_vif.push      = 0;
        fifo_vif.pop       = 0;
        @(posedge fifo_vif.clk);
        @(posedge fifo_vif.clk);
        fifo_vif.rst       = 0;

        @(negedge fifo_vif.clk);
        //assertion check full, empty
        assert (fifo_vif.empty) $display("[DRV Assert] reset pass : empty!");
        else $display("[DRV] Assert reset fail : empty  = %d", fifo_vif.empty);

        assert (!fifo_vif.full) $display("[DRV Assert] reset pass : full");
        else $display("[DRV] Assert reset fail : full  = %d", fifo_vif.full);

        fifo_vif.push = 0;
        fifo_vif.pop = 0;
        fifo_vif.push_data = 0;
    endtask
    task push_only(int cnt);
        $display("fifo push only test");
        repeat (cnt) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = 1;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = 0;
            ->event_gen_next;
        end
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = tr.push;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = tr.pop;
        end
    endtask
endclass

// 5. Monitor
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_vif;

    function new(virtual fifo_interface fifo_vif,
                 mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_vif = fifo_vif;
    endfunction

    task run();
        forever begin
            @(negedge fifo_vif.clk);
            // #1;
            tr = new();
            tr.push = fifo_vif.push;
            tr.pop = fifo_vif.pop;
            tr.push_data = fifo_vif.push_data;
            tr.pop_data = fifo_vif.pop_data;
            tr.full = fifo_vif.full;
            tr.empty = fifo_vif.empty;
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
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    bit [7:0] fifo_queue[$:16];
    bit [7:0] compare_data;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            // FIFO scoreboard logic
            if (tr.push && !tr.full) begin  // write
                fifo_queue.push_front(tr.push_data);
            end
            if (tr.pop && !tr.empty) begin  // read
                // pass/ fail decision
                compare_data = fifo_queue.pop_back();
                if (tr.pop_data == compare_data) begin
                    $display("%t : PASS ", $time);
                    pass_cnt++;
                end else begin
                    $display(
                        "%t : Fail pop = %d , pop_data = %d, empty= %d ,expected data = %d "
                        , $time, tr.pop, tr.pop_data, tr.empty, compare_data);
                    fail_cnt++;
                end
            end
            ->event_gen_next;
        end
    endtask

endclass

// 7. Environment
class environment;
    transaction            tr;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  event_gen_next;
    int                    run_cnt;

    virtual fifo_interface fifo_vif;

    function new(virtual fifo_interface fifo_vif);
        this.fifo_vif = fifo_vif;
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, fifo_vif, event_gen_next);
        mon = new(fifo_vif, mon2scb_mbox);
        scb = new(mon2scb_mbox, event_gen_next);
    endfunction


    task run();
        drv.preset();
        run_cnt = 16;
        fork
            gen.run(run_cnt);
            drv.push_only(run_cnt);
            mon.run();
            scb.run();
        join
        $display("[ENV] push push_only test end");
        #10;
        if (fifo_vif.full) $display("PASS : push only test");
        else $display("FAIL : push only test");

        #10;
        $display("env run task end");
        $display("________________");
        $display("** FIFO IP Verification");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num = %2d **", scb.pass_cnt);
        $display("** fail test num = %2d **", scb.fail_cnt);
        $stop;
    endtask
endclass

// 8. Top Module
module tb_fifo_sv ();
    logic clk;
    environment env;

    fifo_interface fifo_if ();


    fifo_sv dut (
        .clk      (fifo_if.clk),
        .rst      (fifo_if.rst),
        .push_data(fifo_if.push_data),
        .push     (fifo_if.push),
        .pop      (fifo_if.pop),
        .pop_data (fifo_if.pop_data),
        .full     (fifo_if.full),
        .empty    (fifo_if.empty)
    );


    always #5 fifo_if.clk = ~fifo_if.clk;

    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
    end
endmodule

