`timescale 1ns / 1ps

`timescale 1ns / 1ps

module tb_rv32i_multi();
    logic clk, rst;
    
    top_rv32i_multi dut(.*);

    always #5 clk = ~clk;
    initial begin
        // $dumpfile("instruction.vcd");
        // $dumpvars(0, tb_rv32i_multi);

        clk = 0;
        rst = 1;
        repeat(2) @(negedge clk);
        rst = 0;

        repeat(1500) @(negedge clk);

        $finish;
    end

endmodule
