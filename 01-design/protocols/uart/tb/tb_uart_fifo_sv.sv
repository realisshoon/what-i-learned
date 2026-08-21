`timescale 1ns / 1ps

// 1. Interface
interface fifo_interface;
    logic   clk;
    logic      rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
endinterface
    
// 2-a. Mode Enum
typedef enum bit [1:0] {
    IDLE      = 2'b00,   // push=0, pop=0
    POP_ONLY  = 2'b01,   // push=0, pop=1
    PUSH_ONLY = 2'b10,   // push=1, pop=0
    PUSH_POP  = 2'b11    // push=1, pop=1
} fifo_mode_t;

// 2-b. Transaction
class transaction;
    rand bit [7:0] push_data;
    rand bit       push;
    rand bit       pop;
    bit      [7:0] pop_data;
    bit            full;
    bit            empty;
    fifo_mode_t    mode;

    function void debug_print(string name);
        $display(
            "[%s] Time: %0t | mode: %-9s | push_data: 0x%02h | pop_data: 0x%02h | full: %0d | empty: %0d"
            , name, $time, mode.name(), push_data, pop_data, full, empty);
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
    task push_only_to_full();
        $display("[DRV] fifo push only test to full");
        while (1) begin
            @(posedge fifo_vif.clk);
            #1;
            if (fifo_vif.full) begin
                fifo_vif.push = 0;
                break;
            end else begin
                gen2drv_mbox.get(tr);
                fifo_vif.push      = 1;
                fifo_vif.push_data = tr.push_data;
                fifo_vif.pop       = 0;
                tr.debug_print("DRV");
                ->event_gen_next;
            end
        end

        @(posedge fifo_vif.clk);
        #1;
        fifo_vif.push = 0;
        assert(fifo_vif.full) $display("[DRV Assert] Pass : fifo full!");
        else $error("[DRV Assert] Fail");
    endtask

    task pop_only_to_empty();
        while(1) begin
            @(posedge fifo_vif.clk);
            #1;
            if (fifo_vif.empty) begin
                fifo_vif.pop = 0;
                break;
            end else begin
                fifo_vif.push      = 0;
                fifo_vif.pop       = 1;
            end
        end

        @(posedge fifo_vif.clk);
        #1;
        fifo_vif.pop = 0;
        assert(fifo_vif.empty) $display("[DRV Assert] Pass : fifo empty");
        else $error("[DRV Assert] Fail");
    endtask

    task push_pop(int cnt);
        $display("[DRV] fifo push+pop simultaneous test (cnt=%0d)", cnt);
        repeat (cnt) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = 1;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = 1;
            ->event_gen_next;
        end
        @(posedge fifo_vif.clk);
        #1;
        fifo_vif.push = 0;
        fifo_vif.pop  = 0;
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
            tr = new();
            tr.push      = fifo_vif.push;
            tr.pop       = fifo_vif.pop;
            tr.push_data = fifo_vif.push_data;
            tr.pop_data  = fifo_vif.pop_data;
            tr.full      = fifo_vif.full;
            tr.empty     = fifo_vif.empty;
            tr.mode      = fifo_mode_t'({fifo_vif.push, fifo_vif.pop});

            if (tr.mode == POP_ONLY || tr.mode == PUSH_POP) begin
                $display("[MON] Time : %t | pop data : %02h\n", $time, tr.pop_data);
            end

            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
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

            case (tr.mode)
                PUSH_ONLY: begin
                    if (!tr.full) begin
                        fifo_queue.push_front(tr.push_data);
                        $display("[SCB] PUSH_ONLY  | wrote 0x%02h | depth=%0d",
                                 tr.push_data, fifo_queue.size());
                        pass_cnt++;
                        total_cnt++; 
                    end else begin
                        $display("[SCB] PUSH_ONLY  | BLOCKED (full)");
                    end
                end

                POP_ONLY: begin
                    if (!tr.empty) begin
                        compare_data = fifo_queue.pop_back();
                        if (tr.pop_data == compare_data) begin
                            $display("[SCB] POP_ONLY   | PASS read=0x%02h exp=0x%02h | depth=%0d",
                                     tr.pop_data, compare_data, fifo_queue.size());
                            pass_cnt++;
                        end else begin
                            $display("[SCB] POP_ONLY   | FAIL read=0x%02h exp=0x%02h",
                                     tr.pop_data, compare_data);
                            fail_cnt++;
                        end
                        total_cnt++;
                    end else begin
                        $display("[SCB] POP_ONLY   | BLOCKED (empty)");
                    end
                end

                PUSH_POP: begin

                    if (!tr.full) begin
                        fifo_queue.push_front(tr.push_data);
                    end

                    if (!tr.empty) begin
                        compare_data = fifo_queue.pop_back();
                        if (tr.pop_data == compare_data) begin
                            $display("[SCB] PUSH_POP   | PASS read=0x%02h exp=0x%02h depth=%0d",
                                     tr.pop_data, compare_data, fifo_queue.size());
                            pass_cnt++;
                        end else begin
                            $display("[SCB] PUSH_POP   | FAIL read=0x%02h exp=0x%02h",
                                     tr.pop_data, compare_data);
                            fail_cnt++;
                        end
                        total_cnt++;
                    end
                end

                IDLE: ;
            endcase
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
        int max_depth   = 16;
        int gap_clk     = 5;
        int pushpop_cnt = 8;

        drv.preset();


        //background mon/scb
        fork
            mon.run();
            scb.run();
        join_none


        $display("[ENV] push_only until full ");
        fork : push_only_fork
            gen.run(max_depth * 2);
            drv.push_only_to_full();
        join_any
        disable push_only_fork;



        repeat (gap_clk) @(posedge fifo_vif.clk);

        $display("[ENV] pop_only until empty");
        drv.pop_only_to_empty();


        $display("[ENV] push+pop x%0d", pushpop_cnt);
        fork
            gen.run(pushpop_cnt);
            drv.push_pop(pushpop_cnt);
        join
        #100;

        disable fork;

        #20;
        $display("________________");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
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
