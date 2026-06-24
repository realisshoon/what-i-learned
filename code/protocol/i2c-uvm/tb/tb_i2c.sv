import uvm_pkg::*;
import i2c_pkg::*;

module tb_i2c ();

    logic clk;

    initial clk = 0;
    always #5 clk = ~clk;

    i2c_if vif (.clk(clk));

    i2c_master_slave_top #(
        .SLAVE_ADDR(7'h12)
    ) dut (
        .clk  (clk),
        .reset(vif.reset),

        .cmd_start(vif.cmd_start),
        .cmd_write(vif.cmd_write),
        .cmd_read (vif.cmd_read),
        .cmd_stop (vif.cmd_stop),

        .master_tx_data(vif.master_tx_data),
        .master_rx_data(vif.master_rx_data),

        .ack_in (vif.master_read_ack),
        .ack_out(vif.slave_ack_received),

        .master_busy(vif.master_busy),
        .master_done(vif.master_done),

        .slave_tx_data(vif.slave_tx_data),
        .slave_rx_data(vif.slave_rx_data),
        .slave_rx_done(vif.slave_rx_done),
        .slave_tx_done(vif.slave_tx_done),

        .slave_addr_match(vif.slave_addr_match),
        .slave_rw_mode   (vif.slave_rw_mode),
        .slave_master_ack(vif.slave_master_ack),
        .slave_busy      (vif.slave_busy),

        .scl(vif.scl),
        .sda(vif.sda)
    );

    initial begin
        vif.reset           = 1'b1;

        vif.cmd_start       = 1'b0;
        vif.cmd_write       = 1'b0;
        vif.cmd_read        = 1'b0;
        vif.cmd_stop        = 1'b0;

        vif.master_tx_data  = 8'd0;
        vif.master_read_ack = 1'b1;  // default NACK
        vif.slave_tx_data   = 8'd0;

        repeat (10) @(posedge clk);
        vif.reset = 1'b0;
    end


    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("./out/wave/tb_i2c.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end

endmodule
