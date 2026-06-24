`timescale 1ns / 1ps

module tb_dedicated();
    logic clk;
    logic rst;
    logic [7:0] out;
    dedicated_cpu_counter dut(.*);

    always #5 clk = ~clk;

    initial begin
         clk = 0;
         rst = 1;
         @(negedge clk);
         @(negedge clk);
         rst = 0;
         #120;
         $stop;
    end

endmodule
