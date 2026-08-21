`timescale 1ns/1ps

class transaction;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit mode;
    bit      [7:0] s;
    bit            c;

    function debug_print(string name);
        $display("%t : [%s] a = %d , b = %d",$time, name, a, b );
    endfunction
endclass:transaction

interface adder_interface ();
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] s;
    logic       c;
endinterface:adder_interface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task run();
        tr = new();
        tr.randomize();
        tr.debug_print("GEN");
        gen2drv_mbox.put(tr);
    endtask
endclass



module tb_alu_sv();


endmodule
