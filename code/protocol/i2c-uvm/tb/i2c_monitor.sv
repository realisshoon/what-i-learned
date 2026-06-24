class i2c_monitor extends uvm_component;

    `uvm_component_utils(i2c_monitor)

    virtual i2c_if vif;

    uvm_analysis_port #(i2c_seq_item) ap;

    function new(string name = "i2c_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Failed to get virtual interface")
        end
    endfunction

    task automatic sample_ack_from_sda(output logic ack_value);
        // I2C ACK/NACK는 8bit 전송 이후 9번째 SCL clock에서 결정됨
        // ACK  = SDA Low  = 0
        // NACK = SDA High / Release = 1

        repeat (9) begin
            @(posedge vif.scl);
        end

        #1step;

        if (vif.sda === 1'b0) begin
            ack_value = 1'b0;  // ACK
        end else begin
            ack_value = 1'b1;  // NACK or released bus
        end

        `uvm_info("MON", $sformatf("ACK/NACK sampled from SDA: sda=%b ack_value=%0b", vif.sda,
                                   ack_value), UVM_MEDIUM)
    endtask

    virtual task run_phase(uvm_phase phase);
        i2c_seq_item item;

        logic [7:0] addr_byte;
        logic [7:0] data_byte;

        wait (vif.reset == 1'b0);

        forever begin
            // ----------------------------------------------------
            // 1. I2C transaction 시작 감지
            // ----------------------------------------------------
            @(posedge vif.mon_cb.cmd_start);

            item = i2c_seq_item::type_id::create("mon_item");

            `uvm_info("MON", "Detected I2C START command", UVM_MEDIUM)

            // ----------------------------------------------------
            // 2. Address phase 감지
            //    ADDR+W 또는 ADDR+R 모두 Master가 write command로 보냄
            // ----------------------------------------------------
            @(posedge vif.mon_cb.cmd_write);
            #1step;

            addr_byte = vif.mon_cb.master_tx_data;

            item.slave_addr = addr_byte[7:1];

            if (addr_byte[0] == 1'b0) begin
                item.op = i2c_seq_item::I2C_WRITE;
            end else begin
                item.op = i2c_seq_item::I2C_READ;
            end

            `uvm_info("MON", $sformatf(
                      "Address phase detected: addr_byte=0x%02h slave_addr=0x%02h op=%s",
                      addr_byte,
                      item.slave_addr,
                      (item.op == i2c_seq_item::I2C_WRITE) ? "WRITE" : "READ"
                      ), UVM_MEDIUM)

            do begin
                @(vif.mon_cb);
            end while (vif.mon_cb.master_done !== 1'b1);

            @(vif.mon_cb);
            item.slave_ack_received = vif.mon_cb.slave_ack_received;

            // ----------------------------------------------------
            // 3-A. WRITE transaction
            // START -> ADDR+W -> DATA -> STOP
            // ----------------------------------------------------
            if (item.op == i2c_seq_item::I2C_WRITE) begin

                // Data write command 감지
                @(posedge vif.mon_cb.cmd_write);
                #1step;

                data_byte       = vif.mon_cb.master_tx_data;
                item.write_data = data_byte;

                `uvm_info("MON", $sformatf("Write data phase detected: write_data=0x%02h",
                                           item.write_data), UVM_MEDIUM)

                // Slave가 data byte 수신 완료할 때까지 대기
                @(posedge vif.mon_cb.slave_rx_done);
                #1step;

                item.slave_rx_data = vif.mon_cb.slave_rx_data;

                `uvm_info("MON",
                          $sformatf("Observed WRITE result: expected=0x%02h actual_slave_rx=0x%02h",
                                    item.write_data, item.slave_rx_data), UVM_LOW)

                ap.write(item);
            end  // ----------------------------------------------------
                 // 3-B. READ transaction
            // START -> ADDR+R -> READ -> STOP
            // ----------------------------------------------------
            else begin

                // Read command 감지
                @(posedge vif.mon_cb.cmd_read);
                #1step;

                item.slave_tx_data = vif.mon_cb.slave_tx_data;

                `uvm_info("MON", $sformatf(
                          "Read data phase detected: slave_tx_data=0x%02h", item.slave_tx_data),
                          UVM_MEDIUM)

                // Master read command 완료 대기
                @(posedge vif.mon_cb.master_done);
                #1step;

                item.master_rx_data = vif.mon_cb.master_rx_data;

                `uvm_info("MON", $sformatf(
                          "Observed READ result: expected_slave_tx=0x%02h actual_master_rx=0x%02h",
                          item.slave_tx_data,
                          item.master_rx_data
                          ), UVM_LOW)

                ap.write(item);
            end
        end
    endtask

endclass
