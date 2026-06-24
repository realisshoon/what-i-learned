`timescale 1ns / 1ps


class transaction;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit       mode;
    bit      [7:0] s;
    bit            c;

    function debug_print(string name);
        $display("%t : [%s] a = %d, b = %d, mode = %d s = %d, c = %d", $time, name, a, b,
                mode,s,c);
    endfunction

    // constraint in_range {
    //     a>128;
    //     b>250;
    // }

    constraint in_range {
        a inside {[0:127]};
    }

    constraint in_b{
        if (mode == 0)
            b inside {0,1,2,3,15,31,250};
        else
            b > 128;
    }

    constraint mode_distribute {
        mode dist {0:/90,1:/10};  // "/" 확률을 뜻함
    }

endclass : transaction

interface adder_interface ();

    // 멤버 변수
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] s;
    logic       c;
endinterface : adder_interface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next; 

    function new(mailbox#(transaction) gen2drv_mbox, event e);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_gen_next = e;
    endfunction


    task run(int cnt);
    repeat(cnt) begin
            tr = new();
            tr.randomize();
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
        $display("GEN end task");
    endtask

endclass : generator


// to drive by interface stimulus
class driver;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event e,
                virtual adder_interface adder_vinterf);
        this.adder_vif = adder_vinterf;
        this.event_gen_next = e;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task run();
    forever begin
        gen2drv_mbox.get(tr);
        tr.debug_print("DRV");
        adder_vif.a    = tr.a;
        adder_vif.b    = tr.b;
        adder_vif.mode = tr.mode;
        #10;

        -> event_gen_next;
    end 
    $display("DRV end task");

    endtask : run

endclass : driver

class monitor;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) mon2scv_mbox;
    function new(mailbox #(transaction) mon2scv_mbox, virtual adder_interface adder_vinterf);
        this.mon2scv_mbox = mon2scv_mbox;
        this.adder_vif    = adder_vinterf;
    endfunction

    task run();
    forever begin
        #5;
        tr = new;
        tr.a = adder_vif.a;
        tr.b = adder_vif.b;
        tr.mode =adder_vif.mode;
        tr.s = adder_vif.s;
        tr.c=adder_vif.c;
        mon2scv_mbox.put(tr);
        tr.debug_print("MON");
        #5;
    end
    endtask

endclass : monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scv_mbox;
    int total_cnt = 0, pass_cnt=0, fail_cnt=0;

    function new(mailbox #(transaction) mon2scv_mbox);
        this.mon2scv_mbox = mon2scv_mbox;
    endfunction

    task run();
        bit [7:0] expected_s;
        bit expected_c;

        forever begin
            mon2scv_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            if (tr.mode) begin
                {expected_c,expected_s} = tr.a-tr.b;
            end else  begin
                {expected_c,expected_s} = tr.a+tr.b;
            end
            if ((tr.s == expected_s) && (tr.c == expected_c)) begin
                $display("%t, pass",$time);
                pass_cnt++;
            end else begin
                $display(
                    "%t, fail !! mode = %d, a = %d, b= %d, sum=%d, carry= %d",
                    $time,tr.mode,tr.a,tr.b,tr.s,tr.c);
                fail_cnt++;
            end
        end
    endtask

endclass

// manager
class environment;
    generator       gen;
    driver          drv;
    monitor         mon;
    scoreboard      scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scv_mbox;
    event event_gen_next; 

    function new(virtual adder_interface adder_vif);
        gen2drv_mbox = new;
        mon2scv_mbox = new;
        gen = new(gen2drv_mbox,event_gen_next);
        drv = new(gen2drv_mbox,event_gen_next,adder_vif);
        mon = new(mon2scv_mbox, adder_vif);
        scb = new(mon2scv_mbox);
    endfunction

    task run(int cnt);
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("ENV fork join_any end");

        $display("___________________________________________");
        $display("전체 테스트 개수 %0d ",scb.total_cnt);
        $display("성공한 개수 %0d",scb.pass_cnt);
        $display("실패한 개수 %0d",scb.fail_cnt);
        $display("성공율 %0d %%",(scb.pass_cnt/(scb.total_cnt)*100));
        $display("___________________________________________");

    endtask : run


endclass:environment


module tb_alu_sv ();

    adder_interface adder_if ();
    environment env;



    adder dut (
        // 인스턴스 변수(멤버 연결자.멤버 변수)
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        env = new(adder_if);
        env.run(10);
        $stop;
    end

endmodule : tb_alu_sv
