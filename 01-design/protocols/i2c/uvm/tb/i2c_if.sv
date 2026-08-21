interface i2c_if (
    input logic clk
);
    logic       reset;

    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;

    logic [7:0] master_tx_data;
    logic [7:0] master_rx_data;

    logic       master_read_ack;  // DUT ack_in
    logic       slave_ack_received;  // DUT ack_out

    logic       master_busy;
    logic       master_done;

    // slave
    logic [7:0] slave_rx_data;
    logic [7:0] slave_tx_data;
    logic       slave_rx_done;
    logic       slave_tx_done;
    logic       slave_addr_match;
    logic       slave_rw_mode;
    logic       slave_master_ack;
    logic       slave_busy;

    // i2c bus
    logic       scl;
    logic       sda;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;

        output reset;
        output cmd_start;
        output cmd_write;
        output cmd_read;
        output cmd_stop;
        output master_tx_data;
        output master_read_ack;
        output slave_tx_data;

        input master_busy;
        input master_done;
        input slave_ack_received;
        input scl;
        input sda;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;

        input reset;

        input cmd_start;
        input cmd_write;
        input cmd_read;
        input cmd_stop;

        input master_tx_data;
        input master_rx_data;
        input master_read_ack;
        input slave_ack_received;

        input master_busy;
        input master_done;

        input slave_tx_data;
        input slave_rx_data;
        input slave_rx_done;
        input slave_tx_done;
        input slave_addr_match;
        input slave_rw_mode;
        input slave_master_ack;
        input slave_busy;

        input scl;
        input sda;
    endclocking

endinterface
