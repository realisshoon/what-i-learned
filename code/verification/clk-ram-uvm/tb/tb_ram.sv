import uvm_pkg::*;
import ram_pkg::*;

module tb_top ();
    logic clk;

    initial clk = 0;
    always #5 clk = ~clk;


    ram_if r_if (.clk(clk));

    ram dut (
        .clk  (clk),
        .we   (r_if.we),
        .wdata(r_if.wdata),
        .addr (r_if.addr),
        .rdata(r_if.rdata)
    );


    initial begin
        uvm_config_db#(virtual ram_if)::set(null, "*", "r_if", r_if);
        run_test();
    end

    initial begin
        $fsdbDumpfile("../wave/ram_tb.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end

endmodule
