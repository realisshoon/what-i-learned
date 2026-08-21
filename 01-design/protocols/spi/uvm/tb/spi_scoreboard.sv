class spi_scoreboard extends uvm_component;

    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) imp;

    int pass_cnt;
    int fail_cnt;

    function new(string name = "spi_scoreboard", uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
        pass_cnt = 0;
        fail_cnt = 0;
    endfunction

    virtual function void write(spi_seq_item item);

        bit slave_rx_pass;
        bit master_rx_pass;

        slave_rx_pass  = (item.slave_rx_data === item.master_tx_data);
        master_rx_pass = (item.master_rx_data === item.slave_tx_data);

        if (!slave_rx_pass) begin
            fail_cnt++;
            `uvm_error("SCB", $sformatf("Slave RX mismatch | master_tx=0x%02h, slave_rx=0x%02h",
                                        item.master_tx_data, item.slave_rx_data))
        end else begin
            pass_cnt++;
            `uvm_info("SCB", $sformatf(
                      "PASS Slave RX | master_tx=0x%02h, slave_rx=0x%02h",
                      item.master_tx_data,
                      item.slave_rx_data
                      ), UVM_LOW)
        end

        if (!master_rx_pass) begin
            fail_cnt++;
            `uvm_error("SCB", $sformatf("Master RX mismatch | slave_tx=0x%02h, master_rx=0x%02h",
                                        item.slave_tx_data, item.master_rx_data))
        end else begin
            pass_cnt++;
            `uvm_info("SCB", $sformatf(
                      "PASS Master RX | slave_tx=0x%02h, master_rx=0x%02h",
                      item.slave_tx_data,
                      item.master_rx_data
                      ), UVM_LOW)
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB", $sformatf("SPI Scoreboard Report | PASS=%0d, FAIL=%0d", pass_cnt, fail_cnt
                  ), UVM_NONE)
    endfunction

endclass
