`timescale 1ns / 1ps

interface ram_intf (
    input logic clk
);
  logic we;
  logic [7:0] addr;
  logic [7:0] wdata;
  logic [7:0] rdata;
endinterface  //ram_intf

class transaction;
  rand logic [7:0] addr;
  rand logic [7:0] data;
  logic [7:0] rdata;
endclass  //transaction




class tester;
  transaction tr;

  virtual ram_intf ram_if;

  function new(virtual ram_intf ram_if);
    this.ram_if = ram_if;
    tr = new();
  endfunction  //new()

  task write();
    ram_if.we = 1;
    ram_if.addr = tr.addr;
    ram_if.wdata = tr.data;
    @(posedge ram_if.clk);
    $display("we: %0h, addr: %0h, wdata : %0h", ram_if.we, ram_if.addr, ram_if.wdata);
  endtask

  task read();
    ram_if.we   = 0;
    ram_if.addr = tr.addr;
    @(posedge ram_if.clk);
    tr.rdata = ram_if.rdata;
    $display("we: %0h, addr: %0h, rdata : %0h", ram_if.we, ram_if.addr, ram_if.rdata);
  endtask

  virtual function result();
    if (tr.data != tr.rdata) begin
      $display("          Fail! wdata :%0h != rdata : %0h", tr.data, tr.rdata);
    end else begin
      $display("Pass! wdata :%0h == rdata : %0h", tr.data, tr.rdata);
    end

  endfunction


  virtual task test_run(int loop_cnt);
    repeat (loop_cnt) begin
      tr.randomize();
      write();
      read();
      result();
    end
  endtask

endclass  //tester

class tester_child extends tester;
  int pass, fail;

  function new(virtual ram_intf ram_if);
    super.new(ram_if);
    pass = 0;
    fail = 0;
  endfunction  //new()

  virtual function result();
    if (tr.data != tr.rdata) begin
      $display("          Fail! wdata :%0h != rdata : %0h", tr.data, tr.rdata);
      fail++;
    end else begin
      $display("Pass! wdata :%0h == rdata : %0h", tr.data, tr.rdata);
      pass++;
    end

  endfunction

  function report();
    $display("pass count : %0d", pass);
    $display("fail count : %0d", fail);
    $display("total test count : %0d", pass + fail);
  endfunction

  virtual task test_run(int loop_cnt);
    repeat (loop_cnt) begin
      tr.randomize();
      write();
      read();
      result();
    end
    report();
  endtask
endclass  //tester_child extends tester



module tb_RAM ();
  logic clk;
  ram_intf ram_if (clk);

  ram dut (
      .clk(ram_if.clk),
      .we(ram_if.we),
      .addr(ram_if.addr),
      .wdata(ram_if.wdata),
      .rdata(ram_if.rdata)
  );

  tester TESTER;
  tester_child TESTER_child;


  initial begin
    TESTER = new(ram_if);
    clk = 0;
    repeat (5) @(posedge clk);
  end

  always #5 ram_if.clk = ~ram_if.clk;

  initial begin
    // TESTER.write(8'hA0, 8'h01);
    // #10;
    // TESTER.read(8'hA0);
    // #10;
    // TESTER.write(8'hB0, 8'h02);
    // #10;
    // TESTER.read(8'hB0);
    // #10;
    // TESTER.write(8'hC0, 8'h03);
    // #10;
    // TESTER.read(8'hC0);

    // repeat(100) begin
    //     TESTER.randomize();
    //     TESTER.write();
    //     TESTER.read();
    // end

    TESTER.test_run(10);

    repeat (5) @(posedge clk);

    $finish;
  end

endmodule
