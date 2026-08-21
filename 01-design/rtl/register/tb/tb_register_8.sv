`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] d;
    bit [7:0] q;

    function void print_debug(string name);
        $display("%t : [%0s] d=%0d, q=%0d", $time, name,d,q);
    endfunction
endclass:transaction

interface reg_if;
    logic       clk;
    logic       reset;
    logic [7:0] d;
    logic [7:0] q;
endinterface:reg_if

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(
        mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_gen_next =event_gen_next;
    endfunction

    task run(int cnt);
        repeat(cnt) begin
            tr = new();
            tr.randomize();
            tr.print_debug("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask
endclass:generator

class driver;
    transaction tr;
    mailbox#(transaction) gen2drv_mbox;
    event event_mon_next;
    virtual reg_if reg_vif;


    function new(mailbox#(transaction) gen2drv_mbox,
                    event event_mon_next,
                    virtual reg_if reg_vinterf);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif = reg_vinterf;
    endfunction

    task preset;
        reg_vif.reset = 1'b1;
        repeat(2) @(posedge reg_vif.clk);
        reg_vif.reset = 1'b0;
    endtask

    task run();
        forever begin
            @(posedge reg_vif.clk);
            #1;
            gen2drv_mbox.get(tr);
            reg_vif.d = tr.d;
            tr.print_debug("DRV");
            @(negedge reg_vif.clk);
            -> event_mon_next;
        end
    endtask

endclass


class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_mon_next;
    virtual reg_if reg_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
    event event_mon_next,
    virtual reg_if reg_vif);
        this.mon2scb_mbox =mon2scb_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif=reg_vif;
    endfunction

    task run();
        forever begin
            @(event_mon_next);
            @(posedge reg_vif.clk);
            tr=new;
            tr.d= reg_vif.d;
            #1;
            tr.q = reg_vif.q;
            tr.print_debug("MON");
            mon2scb_mbox.put(tr);
        end
    endtask

endclass

class scoreboard;
    transaction tr;
    mailbox#(transaction) mon2scb_mbox;
    event event_gen_next;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.print_debug("SCB");
            total_cnt++;
            if(tr.d==tr.q)begin
                pass_cnt++;
                $display("%t : PASS !!", $time);
            end else begin
                fail_cnt++;
                $display("%t : FAIL !! d=%0d, q=%0d",$time,tr.d,tr.q);
            end
            -> event_gen_next;
        end
    endtask
endclass

class environment;
    transaction             tr;
    generator               gen;
    driver                  drv;
    monitor                 mon;
    scoreboard              scb;
    mailbox#(transaction)   gen2drv_mbox;
    mailbox#(transaction)   mon2scb_mbox;
    event                   event_gen_next;
    event                   event_mon_next;

    function new(virtual reg_if reg_vif);
        this.gen2drv_mbox = new;
        this.mon2scb_mbox = new;
        gen     = new(gen2drv_mbox,event_gen_next);
        drv     = new(gen2drv_mbox,event_mon_next, reg_vif);
        mon     = new(mon2scb_mbox,event_mon_next, reg_vif);
        scb     = new(mon2scb_mbox,event_gen_next);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("%t : ENV fork join_any end ",$time);
        #20;

        $display("\n==================== test end ====================");
        $display(" Total Test : %0d", scb.total_cnt);
        $display(" Pass Test  : %0d", scb.pass_cnt);
        $display(" Fail Test  : %0d", scb.fail_cnt);
        $display("================================================");

        $stop;
    endtask

endclass




module tb_register_8();

    reg_if reg_if();
    environment env;

register_8 dut(
    .clk(reg_if.clk),
    .reset(reg_if.reset),
    .d(reg_if.d),
    .q(reg_if.q)
    );

    always #5 reg_if.clk = ~reg_if.clk;
    initial begin
        reg_if.clk = 0;
        env=new(reg_if);
        env.run();
    end


endmodule
