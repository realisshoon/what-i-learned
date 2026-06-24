`timescale 1ns / 1ps

// 1. Interface
interface ascii_if;
    logic       clk;
    logic       rst;
    logic [7:0] ascii_in;
    logic       read_en;
    logic [4:0] ascii_out;
endinterface

// 2. Transaction
class transaction;
    rand bit [7:0] ascii_in;
    rand int       hold_clocks;
    
    bit [4:0]      ascii_out;

    task debug_print(string name);
        $display("[%s] %0t  ascii_in : %h, ascii_out : %b", name, $time, ascii_in, ascii_out);
    endtask

    constraint c_data {
        ascii_in dist {
            8'h73 := 10, 8'h32 := 10, 8'h34 := 10, 8'h36 := 10, 8'h38 := 10,
            [8'h00 : 8'h31] :/ 70, [8'h39 : 8'h72] :/ 30
        };
    }

    constraint c_hold {
        hold_clocks inside {[1:5]};
    }

endclass

// 3. Generator
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event event_packet_done;

    function new(mailbox#(transaction) gen2drv_mbox, mailbox#(transaction) gen2scb_mbox, event event_packet_done);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_packet_done = event_packet_done;
    endfunction



    task run(int cnt);
        repeat(cnt) begin
            tr = new();
            assert (tr.randomize()) else $error("Randomization failed");
            tr.debug_print("gen");

            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            @(event_packet_done);
        end
    endtask

    task run_single(bit [7:0] target_char);
        tr = new();
        assert (tr.randomize() with { ascii_in == target_char; }) 
        else $error("[GEN] Randomization failed");
        gen2drv_mbox.put(tr);
        gen2scb_mbox.put(tr);
        tr.debug_print("GEN");
    endtask

endclass

// 4. Driver
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ascii_if vif;

    event drv_done;

    function new(mailbox#(transaction) gen2drv_mbox, virtual ascii_if vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.vif = vif;
    endfunction

    task preset();
        vif.rst = 1;
        vif.ascii_in = 8'h00;
        vif.read_en = 0;
        repeat(5) @(posedge vif.clk);
        vif.rst = 0;
    endtask

    task run();
        forever begin
            tr = new();
            gen2drv_mbox.get(tr);
            tr.debug_print("drv");

            vif.ascii_in <= tr.ascii_in;
            vif.read_en <= 1'b1;

            repeat(tr.hold_clocks) @(posedge vif.clk);

            vif.read_en <= 1'b0;
            vif.ascii_in <= 8'h00;
            @(posedge vif.clk);
        end
    endtask
endclass

// 5. Monitor
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ascii_if vif;

    function new(virtual ascii_if vif, mailbox#(transaction) mon2scb_mbox);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        forever begin

            @(posedge vif.clk iff vif.read_en == 1'b1);
            #1;

            tr = new();
            tr.ascii_out = vif.ascii_out;
            mon2scb_mbox.put(tr);
            tr.debug_print("mon");
            wait(vif.read_en == 1'b0);
        end
    endtask
endclass

// 6. Scoreboard
class scoreboard;
    transaction gen_tr;
    transaction mon_tr;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;

    event event_packet_done;

    int pass_cnt = 0, fail_cnt = 0, total_cnt = 0;
    bit [4:0] expected_out;

    function new(mailbox#(transaction) mon2scb_mbox, mailbox#(transaction) gen2scb_mbox, event event_packet_done);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_packet_done = event_packet_done;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(gen_tr);
            mon2scb_mbox.get(mon_tr);
            mon_tr.debug_print("scb");
            total_cnt++;

            case (gen_tr.ascii_in)
                8'h73:   expected_out = 5'b00001; // 's'
                8'h32:   expected_out = 5'b00010; // '2'
                8'h34:   expected_out = 5'b00100; // '4'
                8'h36:   expected_out = 5'b01000; // '6'
                8'h38:   expected_out = 5'b10000; // '8'
                default: expected_out = 5'b00000;
            endcase

            if (mon_tr.ascii_out == expected_out) begin
                $display("[SCB] PASS | TX: %h -> Expected: %b == Read: %b (Hold: %0d clk)", 
                         gen_tr.ascii_in, expected_out, mon_tr.ascii_out, gen_tr.hold_clocks);
                pass_cnt++;
            end else begin
                $display("[SCB] FAIL | TX: %h -> Expected: %b != Read: %b (Hold: %0d clk)", 
                         gen_tr.ascii_in, expected_out, mon_tr.ascii_out, gen_tr.hold_clocks);
                fail_cnt++;
            end
            -> event_packet_done;
        end
    endtask
endclass

// 7. Environment & Top Module
class environment;
    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox = new();
    mailbox #(transaction) mon2scb_mbox = new();
    mailbox #(transaction) gen2scb_mbox = new();
    virtual ascii_if vif;
    event event_packet_done;

    function new(virtual ascii_if vif);
        this.vif = vif;
        gen = new(gen2drv_mbox, gen2scb_mbox, event_packet_done);
        drv = new(gen2drv_mbox, vif);
        mon = new(vif, mon2scb_mbox);
        scb = new(mon2scb_mbox, gen2scb_mbox,event_packet_done);
    endfunction

    task run();
        int test_count = 100;
        real pass_rate;

        drv.preset();
        fork
            gen.run(test_count);
            drv.run();
            mon.run();
            scb.run();
        join_none

        wait(scb.total_cnt == test_count);
        
        repeat(5) @(posedge vif.clk);
        disable fork;

        pass_rate = (real'(scb.pass_cnt)/real'(scb.total_cnt)) *100.0;

        $display("========================================");
        $display("** Total Tests : %0d 개", scb.total_cnt);
        $display("** PASS        : %0d 개", scb.pass_cnt);
        $display("** FAIL        : %0d 개", scb.fail_cnt);
        $display("** Pass Rate   : %.2f %%", pass_rate);
        $display("========================================");
    endtask
endclass

module uart_rx_fifo_sv_top();
    logic clk = 0;
    always #5 clk = ~clk;

    ascii_if vif();
    assign vif.clk = clk;

    ascii_decoder dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .ascii_in(vif.ascii_in),
        .read_en(vif.read_en),
        .ascii_out(vif.ascii_out)
    );

    environment env;

    initial begin
        env = new(vif);
        env.run();
        $stop;
    end
endmodule