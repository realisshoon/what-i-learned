`timescale 1ns / 1ps

interface alu_intf;
    logic [7:0] a, b, result;
    logic opcode;
endinterface  //alu_intf

class tester;
    virtual alu_intf alu_if;

    function new(virtual alu_intf alu_if);
        this.alu_if = alu_if;
    endfunction  //new()

    task add_test(logic [7:0] add_a, logic [7:0] add_b);
        alu_if.opcode = 0;
        alu_if.a = add_a;
        alu_if.b = add_b;
    endtask

    task sub_test(logic [7:0] sub_a, logic [7:0] sub_b);
        alu_if.opcode = 1;
        alu_if.a = sub_a;
        alu_if.b = sub_b;
    endtask


endclass  //tester


module tb_ALU ();
    alu_intf alu_if ();

    alu dut (
        .opcode(alu_if.opcode),
        .a     (alu_if.a),
        .b     (alu_if.b),
        .result(alu_if.result)
    );

    tester BTS;
    tester Blackpink;

    initial begin
        alu_if.opcode = 0;
        alu_if.a = 0;
        alu_if.b = 0;
        #10;
        BTS = new(alu_if); // make instance
        Blackpink = new(alu_if); // make instance
        BTS.add_test(10,20);
        #10;
        BTS.sub_test(10,5);
        #10;
        Blackpink.add_test(4,6);
        #10;
        Blackpink.sub_test(6,4);
        #10;


        $finish;

    end
endmodule
