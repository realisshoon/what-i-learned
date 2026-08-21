class i2c_driver extends uvm_driver #(i2c_seq_item);

    `uvm_component_utils(i2c_driver)

    virtual i2c_if vif;

    function new(string name = "i2c_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Failed to get virtual interface")
        end
    endfunction

    // ------------------------------------------------------------
    // 초기 idle 상태
    // ------------------------------------------------------------
    task drive_idle();
        begin
            vif.drv_cb.cmd_start       <= 1'b0;
            vif.drv_cb.cmd_write       <= 1'b0;
            vif.drv_cb.cmd_read        <= 1'b0;
            vif.drv_cb.cmd_stop        <= 1'b0;

            vif.drv_cb.master_tx_data  <= 8'd0;

            // 1byte read 후 NACK이 기본
            vif.drv_cb.master_read_ack <= 1'b1;

            vif.drv_cb.slave_tx_data   <= 8'd0;
        end
    endtask

    // ------------------------------------------------------------
    // command 완료 대기
    // ------------------------------------------------------------
    task wait_done_timeout(string tag, int max_cycles = 300000);
        int cnt;
        begin
            cnt = 0;

            while ((vif.mon_cb.master_done !== 1'b1) && (cnt < max_cycles)) begin
                @(vif.mon_cb);
                cnt++;
            end

            if (cnt >= max_cycles) begin
                `uvm_error("DRV", $sformatf(
                                      "TIMEOUT waiting master_done: %s busy=%0b scl=%0b sda=%0b",
                                      tag, vif.mon_cb.master_busy, vif.mon_cb.scl, vif.mon_cb.sda))
            end

            @(vif.drv_cb);
        end
    endtask

    // ------------------------------------------------------------
    // START command
    // ------------------------------------------------------------
    task i2c_start();
        begin
            `uvm_info("DRV", "CMD START", UVM_MEDIUM)

            @(vif.drv_cb);
            vif.drv_cb.cmd_start <= 1'b1;

            repeat (2) @(vif.drv_cb);
            vif.drv_cb.cmd_start <= 1'b0;

            wait_done_timeout("START");
        end
    endtask

    // ------------------------------------------------------------
    // WRITE command
    // address byte도 Master가 SDA에 쓰는 값이므로 이 task 사용
    // ------------------------------------------------------------
    task i2c_write(input logic [7:0] data);
        begin
            `uvm_info("DRV", $sformatf("CMD WRITE data=0x%02h", data), UVM_MEDIUM)

            @(vif.drv_cb);
            vif.drv_cb.master_tx_data <= data;
            vif.drv_cb.cmd_write      <= 1'b1;

            repeat (2) @(vif.drv_cb);
            vif.drv_cb.cmd_write <= 1'b0;

            wait_done_timeout($sformatf("WRITE 0x%02h", data));

            // Slave ACK 확인
            // ACK=0, NACK=1
            // if (vif.mon_cb.slave_ack_received !== 1'b0) begin
            //     `uvm_error("DRV",
            //                $sformatf(
            //                    "NACK detected after WRITE data=0x%02h, slave_ack_received=%0b",
            //                    data, vif.mon_cb.slave_ack_received))
            // end


            // ACK는 monitor/scoreboard에서 검증하도록 하고,
            // driver에서는 command 완료 로그만 남긴다.
            `uvm_info(
                "DRV", $sformatf(
                "WRITE done data=0x%02h, slave_ack_received=%b", data, vif.mon_cb.slave_ack_received
                ), UVM_MEDIUM)
        end
    endtask

    // ------------------------------------------------------------
    // READ command
    // master_ack_value: ACK=0, NACK=1
    // 1byte만 읽을 때는 NACK=1
    // ------------------------------------------------------------
    task i2c_read(input logic master_ack_value);
        begin
            `uvm_info("DRV", $sformatf("CMD READ master_read_ack=%0b", master_ack_value),
                      UVM_MEDIUM)

            @(vif.drv_cb);
            vif.drv_cb.master_read_ack <= master_ack_value;
            vif.drv_cb.cmd_read        <= 1'b1;

            repeat (2) @(vif.drv_cb);
            vif.drv_cb.cmd_read <= 1'b0;

            wait_done_timeout("READ");
        end
    endtask

    // ------------------------------------------------------------
    // STOP command
    // STOP은 done 또는 busy=0이면 완료로 인정
    // ------------------------------------------------------------
    task i2c_stop();
        int cnt;
        begin
            `uvm_info("DRV", "CMD STOP", UVM_MEDIUM)

            @(vif.drv_cb);
            vif.drv_cb.cmd_stop <= 1'b1;

            repeat (2) @(vif.drv_cb);
            vif.drv_cb.cmd_stop <= 1'b0;

            cnt = 0;

            while ((vif.mon_cb.master_done !== 1'b1) &&
                   (vif.mon_cb.master_busy !== 1'b0) &&
                   (cnt < 300000)) begin
                @(vif.mon_cb);
                cnt++;
            end

            if (cnt >= 300000) begin
                `uvm_error("DRV", $sformatf("TIMEOUT waiting STOP busy=%0b scl=%0b sda=%0b",
                                            vif.mon_cb.master_busy, vif.mon_cb.scl, vif.mon_cb.sda))
            end

            @(vif.drv_cb);
        end
    endtask

    // ------------------------------------------------------------
    // item 하나 수행
    // ------------------------------------------------------------
    task drive_item(i2c_seq_item item);
        begin
            case (item.op)

                i2c_seq_item::I2C_WRITE: begin
                    `uvm_info("DRV", $sformatf(
                              "Drive WRITE transaction: addr=0x%02h write_data=0x%02h",
                              item.slave_addr,
                              item.write_data
                              ), UVM_LOW)

                    i2c_start();

                    // Address + Write
                    // {7'h12, 1'b0} = 8'h24
                    i2c_write({item.slave_addr, 1'b0});

                    // Data byte
                    i2c_write(item.write_data);

                    i2c_stop();
                end

                i2c_seq_item::I2C_READ: begin
                    `uvm_info("DRV", $sformatf(
                              "Drive READ transaction: addr=0x%02h slave_tx_data=0x%02h",
                              item.slave_addr,
                              item.slave_tx_data
                              ), UVM_LOW)

                    // Slave가 read 때 Master에게 줄 값 세팅
                    @(vif.drv_cb);
                    vif.drv_cb.slave_tx_data <= item.slave_tx_data;

                    repeat (20) @(vif.drv_cb);

                    i2c_start();

                    // Address + Read
                    // {7'h12, 1'b1} = 8'h25
                    i2c_write({item.slave_addr, 1'b1});

                    // 1byte만 읽고 끝내므로 Master NACK
                    i2c_read(1'b1);

                    i2c_stop();
                end

                default: begin
                    `uvm_error("DRV", "Unknown I2C operation")
                end

            endcase
        end
    endtask

    // ------------------------------------------------------------
    // run_phase
    // ------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        i2c_seq_item item;

        drive_idle();

        wait (vif.reset == 1'b0);
        repeat (10) @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);

            `uvm_info("DRV", $sformatf("Received item from sequencer: %s", item.convert2string()),
                      UVM_LOW)

            drive_item(item);

            seq_item_port.item_done();
        end
    endtask

endclass
