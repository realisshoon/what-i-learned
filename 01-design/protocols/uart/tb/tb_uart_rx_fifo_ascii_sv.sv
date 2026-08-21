`timescale 1ns / 1ps

// 1. Interface
interface uart_rx_fifo_if;
    logic       clk;
    logic       rst;
    logic       rx;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
    logic       rx_err_frame;
    logic [4:0] ascii_out;
endinterface

// 2. Transaction
class transaction;
    rand bit [7:0] tx_data;
    bit [4:0]      ascii_out;

    constraint c_data {
        tx_data dist {
            8'h73 := 10, // 's'
            8'h32 := 10, // '2'
            8'h34 := 10, // '4'
            8'h36 := 10, // '6'
            8'h38 := 10, // '8'
            [8'h00 : 8'h31] :/ 70,
            [8'h39 : 8'h72] :/ 30
        };
    }

    function void debug_print(string name);
        $display("[%s] %0t | TX Data: %h ('%c') | ASCII Out: %b", name, $time, tx_data, tx_data, ascii_out);
    endfunction
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

    task run(int count);
        repeat(count) begin
            tr = new();
            assert (tr.randomize()) else $error("[GEN] Randomization failed");
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            @(event_packet_done);
        end
    endtask

    task run_single(bit [7:0] target_char);
        tr = new();
        assert (tr.randomize() with { tx_data == target_char; }) 
        else $error("[GEN] Randomization failed");
        tr.debug_print("GEN");
        gen2drv_mbox.put(tr);
        gen2scb_mbox.put(tr);
        @(event_packet_done);
    endtask
endclass

// 4. Driver
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_rx_fifo_if vif;

    localparam BIT_PERIOD = 8680; // ns for 115200 bps

    function new(mailbox#(transaction) gen2drv_mbox, virtual uart_rx_fifo_if vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.vif = vif;
    endfunction

    task preset();
        vif.rst = 1;
        vif.rx  = 1;
        vif.pop = 0;
        repeat(10) @(posedge vif.clk);
        vif.rst = 0;

        $display("========================================");
        $display("[DRV] TC-01: System Init (Reset & rx=1). Checking ascii_out == 5'b00000");
        repeat(10) @(posedge vif.clk);
        assert(vif.ascii_out == 5'b00000) $display("[DRV] TC-01 PASS : ascii_out 유지됨");
        else $error("[DRV] TC-01 FAIL : ascii_out is not 00000");
    endtask

    task run();
        fork
            // UART TX Task
            forever begin
                gen2drv_mbox.get(tr);
                tr.debug_print("DRV_TX");
                
                vif.rx = 0; // START bit
                #(BIT_PERIOD);
                for(int i=0; i<8; i++) begin
                    vif.rx = tr.tx_data[i];
                    #(BIT_PERIOD);
                end
                vif.rx = 1; // STOP bit
                #(BIT_PERIOD);
                #(BIT_PERIOD); // wait a bit more between bytes
            end
            
            // FIFO POP Task
            forever begin
                @(posedge vif.clk);
                if (!vif.empty) begin
                    vif.pop <= 1'b1;
                    @(posedge vif.clk);
                    vif.pop <= 1'b0;
                end else begin
                    vif.pop <= 1'b0;
                end
            end
        join_none
    endtask
endclass

// 5. Monitor
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_rx_fifo_if vif;

    function new(virtual uart_rx_fifo_if vif, mailbox#(transaction) mon2scb_mbox);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        forever begin

            @(posedge vif.clk iff vif.pop == 1'b1);

            #1;
            
            tr = new();
            tr.ascii_out = vif.ascii_out;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
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
            
            total_cnt++;

            case (gen_tr.tx_data)
                8'h73:   expected_out = 5'b00001; // 's'
                8'h32:   expected_out = 5'b00010; // '2'
                8'h34:   expected_out = 5'b00100; // '4'
                8'h36:   expected_out = 5'b01000; // '6'
                8'h38:   expected_out = 5'b10000; // '8'
                default: expected_out = 5'b00000;
            endcase

            if (mon_tr.ascii_out == expected_out) begin
                $display("%t [SCB] PASS | TX: %h ('%c') -> Expected: %b == Read: %b", 
                         $time, gen_tr.tx_data, gen_tr.tx_data, expected_out, mon_tr.ascii_out);
                pass_cnt++;
            end else begin
                $display("%t [SCB] FAIL | TX: %h ('%c') -> Expected: %b != Read: %b", 
                         $time, gen_tr.tx_data, gen_tr.tx_data, expected_out, mon_tr.ascii_out);
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
    virtual uart_rx_fifo_if vif;
    event event_packet_done;

    function new(virtual uart_rx_fifo_if vif);
        this.vif = vif;
        gen = new(gen2drv_mbox, gen2scb_mbox, event_packet_done);
        drv = new(gen2drv_mbox, vif);
        mon = new(vif, mon2scb_mbox);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_packet_done);
    endfunction

    task run();
        int test_count = 100;
        real pass_rate;

        drv.preset();
        
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none


        $display("========================================");
        $display("[ENV] TC-02: Single Valid Character ('s') 115200bps 전송");
        gen.run_single(8'h73); // 's'


        $display("========================================");
        $display("[ENV] TC-03: Random Packet Verification (%0d회 연속 전송)", test_count);
        gen.run(test_count);

        wait(scb.total_cnt == test_count + 1); // +1 for TC-02
        
        #(drv.BIT_PERIOD * 10); // wait for last operations
        disable fork;

        pass_rate = (real'(scb.pass_cnt)/real'(scb.total_cnt)) * 100.0;

        $display("========================================");
        $display("** Total Tests : %0d 개", scb.total_cnt);
        $display("** PASS        : %0d 개", scb.pass_cnt);
        $display("** FAIL        : %0d 개", scb.fail_cnt);
        $display("** Pass Rate   : %.2f %%", pass_rate);
        $display("========================================");
    endtask
endclass

module tb_uart_rx_fifo_ascii_sv();
    logic clk = 0;
    always #5 clk = ~clk; // 100MHz

    uart_rx_fifo_if vif();
    assign vif.clk = clk;
    logic w_read_en;
    assign w_read_en = !vif.empty&&vif.pop;

    uart_rx_fifo_sv_top dut_uart_fifo (
        .clk(vif.clk),
        .rst(vif.rst),
        .rx(vif.rx),
        .pop(vif.pop),
        .pop_data(vif.pop_data),
        .full(vif.full),
        .empty(vif.empty),
        .rx_err_frame(vif.rx_err_frame)
    );

    ascii_decoder dut_ascii (
        .clk(vif.clk),
        .rst(vif.rst),
        .ascii_in(vif.pop_data),
        .read_en(w_read_en),
        .ascii_out(vif.ascii_out)
    );

    environment env;

    initial begin
        env = new(vif);
        env.run();
        $stop;
    end
endmodule
