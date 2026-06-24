import uvm_pkg::*;
import spi_pkg::*;

module tb_spi ();

    logic clk;

    initial clk = 0;
    always #5 clk = ~clk;

    spi_if s_if (.clk(clk));

    spi_master_slave_top dut (
        .clk  (clk),
        .reset(s_if.reset),

        .start  (s_if.start),
        .clk_div(s_if.clk_div),

        .master_tx_data(s_if.master_tx_data),
        .master_tx_busy(s_if.master_tx_busy),
        .master_rx_data(s_if.master_rx_data),
        .master_rx_done(s_if.master_rx_done),

        .slave_tx_data(s_if.slave_tx_data),
        .slave_tx_busy(s_if.slave_tx_busy),
        .slave_rx_data(s_if.slave_rx_data),
        .slave_rx_done(s_if.slave_rx_done),

        .sclk(s_if.sclk),
        .mosi(s_if.mosi),
        .miso(s_if.miso),
        .cs_n(s_if.cs_n)
    );

    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "*", "s_if", s_if);
        run_test();
    end

    initial begin
        $fsdbDumpfile("./out/wave/tb_spi.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end

endmodule
