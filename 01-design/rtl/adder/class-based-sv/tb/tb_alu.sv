`timescale 1ns / 1ps


class transaction;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit       mode;
    bit      [7:0] s;
    bit            c;
endclass : transaction

interface adder_interface();

    // 멤버 변수
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] s;
    logic       c;
endinterface : adder_interface

class generator;
    transaction tr;

    virtual adder_interface addr_vif;

    function new(virtual adder_interface adder_vinterf);
        addr_vif = adder_vinterf;
        tr = new;
    endfunction

    task run(int cnt);
        repeat(cnt) begin
            tr.randomize();
            addr_vif.a = tr.a;
            addr_vif.b = tr.b;
            addr_vif.mode = tr.mode;
            #10;
        end
    endtask
endclass : generator

module tb_alu ();

    adder_interface adder_if();
    generator gen;

    adder dut (
        // 인스턴스 변수(멤버 연결자.멤버 변수)
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        gen = new(adder_if);
        gen.run(10);
        $stop;
    end

endmodule : tb_alu
