class i2c_scoreboard extends uvm_component;

    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) analysis_export;

    localparam logic [6:0] TARGET_ADDR = 7'h12;

    int total_cnt;
    int write_cnt;
    int read_cnt;
    int pass_cnt;
    int fail_cnt;

    function new(string name = "i2c_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(i2c_seq_item item);
        bit is_target_addr;

        total_cnt++;

        is_target_addr = (item.slave_addr == TARGET_ADDR);

        if (item.op == i2c_seq_item::I2C_WRITE) begin
            write_cnt++;
        end else begin
            read_cnt++;
        end

        `uvm_info("SCB", $sformatf(
                  "Received item: op=%s addr=0x%02h write_data=0x%02h slave_tx_data=0x%02h master_rx_data=0x%02h slave_rx_data=0x%02h slave_ack_received=%b",
                  (item.op == i2c_seq_item::I2C_WRITE) ? "WRITE" : "READ",
                  item.slave_addr,
                  item.write_data,
                  item.slave_tx_data,
                  item.master_rx_data,
                  item.slave_rx_data,
                  item.slave_ack_received
                  ), UVM_MEDIUM)

        // ----------------------------------------------------
        // 1. ACK field unknown check
        // ----------------------------------------------------
        if (item.slave_ack_received === 1'bx) begin
            fail_cnt++;
            `uvm_error("SCB", "Slave ACK/NACK is unknown")
            return;
        end

        // ----------------------------------------------------
        // 2. NACK handling
        // Wrong address에서 NACK는 정상 동작
        // ----------------------------------------------------
        if (item.slave_ack_received == 1'b1) begin

            if (!is_target_addr) begin
                pass_cnt++;

                `uvm_info("SCB", $sformatf(
                                     "[PASS][NACK] Wrong address correctly NACKed: addr=0x%02h",
                                     item.slave_addr), UVM_LOW)

                return;
            end else begin
                fail_cnt++;

                `uvm_error("SCB", $sformatf(
                           "[FAIL][NACK] Target address was NACKed: addr=0x%02h", item.slave_addr))

                return;
            end
        end

        // ----------------------------------------------------
        // 3. ACK handling
        // Wrong address에서 ACK가 나오면 실패
        // ----------------------------------------------------
        if (item.slave_ack_received == 1'b0) begin

            if (!is_target_addr) begin
                fail_cnt++;

                `uvm_error("SCB", $sformatf("[FAIL][ACK] Wrong address was ACKed: addr=0x%02h",
                                            item.slave_addr))

                return;
            end

            `uvm_info("SCB", "Slave ACK observed", UVM_LOW)

            // ----------------------------------------------------
            // 4-A. WRITE data compare
            // ----------------------------------------------------
            if (item.op == i2c_seq_item::I2C_WRITE) begin

                if (item.write_data === item.slave_rx_data) begin
                    pass_cnt++;

                    `uvm_info("SCB",
                              $sformatf(
                                  "[PASS][WRITE] expected_slave_rx=0x%02h actual_slave_rx=0x%02h",
                                  item.write_data, item.slave_rx_data), UVM_LOW)
                end else begin
                    fail_cnt++;

                    `uvm_error("SCB", $sformatf(
                               "[FAIL][WRITE] expected_slave_rx=0x%02h actual_slave_rx=0x%02h",
                               item.write_data,
                               item.slave_rx_data
                               ))
                end
            end  // ----------------------------------------------------
                 // 4-B. READ data compare
                 // ----------------------------------------------------
            else begin

                if (item.slave_tx_data === item.master_rx_data) begin
                    pass_cnt++;

                    `uvm_info("SCB",
                              $sformatf(
                                  "[PASS][READ] expected_master_rx=0x%02h actual_master_rx=0x%02h",
                                  item.slave_tx_data, item.master_rx_data), UVM_LOW)
                end else begin
                    fail_cnt++;

                    `uvm_error("SCB", $sformatf(
                               "[FAIL][READ] expected_master_rx=0x%02h actual_master_rx=0x%02h",
                               item.slave_tx_data,
                               item.master_rx_data
                               ))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB", "========================================", UVM_LOW)
        `uvm_info("SCB", "I2C Scoreboard Summary", UVM_LOW)
        `uvm_info("SCB", $sformatf("TOTAL : %0d", total_cnt), UVM_LOW)
        `uvm_info("SCB", $sformatf("WRITE : %0d", write_cnt), UVM_LOW)
        `uvm_info("SCB", $sformatf("READ  : %0d", read_cnt), UVM_LOW)
        `uvm_info("SCB", $sformatf("PASS  : %0d", pass_cnt), UVM_LOW)
        `uvm_info("SCB", $sformatf("FAIL  : %0d", fail_cnt), UVM_LOW)
        `uvm_info("SCB", "========================================", UVM_LOW)
    endfunction

endclass
