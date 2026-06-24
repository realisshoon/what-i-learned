`timescale 1ns / 1ps

interface uart_if;
    logic       clk;
    logic       rst;
    logic       rx;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       rx_err_frame;
endinterface

class transaction;
    rand bit [7:0] data;
    bit      [7:0] rx_data;
    
    bit err_frame;
    int idle_delay;

    function void debug_print(string name);
        $display("[%s] Time: %0t | tx_data: %h | rx_data: %h | err_frame: %b",
                 name, $time, data, rx_data, err_frame);
    endfunction
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    int pkt_cnt = 10;
    event scb2gen_done;

    function new(mailbox#(transaction) gen2drv_mbox, mailbox#(transaction) gen2scb_mbox,event scb2gen_done);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.scb2gen_done   = scb2gen_done;
    endfunction


    task run();
    repeat(pkt_cnt) begin
        tr=new();
        if (!tr.randomize()) $error("Randomization failed");
        tr.err_frame = 0;
        tr.idle_delay = 0;

        gen2drv_mbox.put(tr);
        gen2scb_mbox.put(tr);
        tr.debug_print("GEN");
        @(scb2gen_done);
    end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_if vif;
    event drv_done;
    localparam BAUD_TICK = 868; // 100MHz / 115200

    function new(mailbox#(transaction) gen2drv_mbox, virtual uart_if vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.vif = vif;
    endfunction

    task preset();
        vif.rst = 1;
        vif.rx  = 1;
        repeat(2) @(posedge vif.clk);
        vif.rst = 0; 
        #100;
        $display("%t reset done", $time);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            repeat (tr.idle_delay) @(posedge vif.clk);

            tr.debug_print("DRV Start");

            vif.rx <= 1'b0;
            repeat (BAUD_TICK) @(posedge vif.clk);


            for (int i = 0; i < 8; i++) begin
                vif.rx <= tr.data[i];
                repeat (BAUD_TICK) @(posedge vif.clk);
            end

            vif.rx <= 1'b1;
            repeat (BAUD_TICK) @(posedge vif.clk);




            // if (tr.err_frame) begin
            //     $display("err_frame %t", $time);
            //     vif.rx <= 1'b0;
            // end else begin
            //     vif.rx <= 1'b1;
            // end
            
            // repeat (BAUD_TICK) @(posedge vif.clk);

            // if (tr.err_frame) begin
            //     vif.rx <= 1'b1;
            //     repeat (BAUD_TICK) @(posedge vif.clk);
            // end
        end
    endtask
endclass

// 5. Monitor
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_if vif;

    function new(virtual uart_if vif, mailbox#(transaction) mon2scb_mbox);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            if (vif.rx_done || vif.rx_err_frame) begin
                tr = new();
                tr.rx_data = vif.rx_data;
                tr.err_frame = vif.rx_err_frame;
                mon2scb_mbox.put(tr);
                tr.debug_print("MON_CATCH");
            end
        end
    endtask
endclass

// 6. Scoreboard
class scoreboard;
    transaction gen_tr, mon_tr;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event scb2gen_done;
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox, mailbox#(transaction) gen2scb_mbox,event scb2gen_done);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.scb2gen_done = scb2gen_done;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(mon_tr);
            gen2scb_mbox.get(gen_tr);
            total_cnt++;
            mon_tr.debug_print("SCB");
            if (mon_tr.rx_data == gen_tr.data && mon_tr.err_frame == 1'b0) begin
                $display("PASS : Txdata(%h) == Rxdata(%h)",mon_tr.rx_data,gen_tr.data);
                pass_cnt++;
            end else begin
                $display("%t FAIL : Txdata(%h) == Rxdata(%h)",$time,mon_tr.rx_data,gen_tr.data);
                fail_cnt++;
            end
            -> scb2gen_done;
        end
    endtask
endclass

// 7. Environment
class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    virtual uart_if        vif;

    event scb2gen_done;

    function new(virtual uart_if vif);
        this.vif = vif;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen2scb_mbox = new();

        gen = new(gen2drv_mbox, gen2scb_mbox,scb2gen_done);
        drv = new(gen2drv_mbox, vif);
        mon = new(vif, mon2scb_mbox);
        scb = new(mon2scb_mbox, gen2scb_mbox,scb2gen_done);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

        wait (scb.total_cnt == gen.pkt_cnt);
        disable fork;

        $display("\n========================================");
        $display("** Test Case 03 연속 패킷 검증 결과**");
        $display("** Total tested = %2d **", scb.total_cnt);
        $display("** PASS count   = %2d **", scb.pass_cnt);
        $display("** FAIL count   = %2d **", scb.fail_cnt);
        $display("========================================\n");
        $stop;
    endtask
endclass

module tb_uart_sv ();
    uart_if vif ();
    environment env;

    logic w_b_tick;
    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (vif.clk),
        .rst     (vif.rst),
        .o_tick(w_b_tick)
    );

    uart_rx_sv dut (
        .clk          (vif.clk),
        .rst          (vif.rst),
        .b_tick       (w_b_tick),
        .rx           (vif.rx),
        .rx_data      (vif.rx_data),
        .rx_done      (vif.rx_done),
        .rx_err_frame (vif.rx_err_frame)
    );

    always #5 vif.clk = ~vif.clk; // 100MHz

    initial begin
        vif.clk = 0;
        env = new(vif);
        env.run();
    end
endmodule