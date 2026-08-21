class i2c_sequence extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_sequence)

    function new(string name = "i2c_sequence");
        super.new(name);
    endfunction

    task send_write(bit [7:0] data);
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("write_item");

        start_item(item);

        item.op            = i2c_seq_item::I2C_WRITE;
        item.slave_addr    = 7'h12;
        item.write_data    = data;
        item.slave_tx_data = 8'h00;

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Send WRITE item: addr=0x%02h data=0x%02h", item.slave_addr,
                                   item.write_data), UVM_LOW)
    endtask

    task send_read(bit [7:0] slave_data);
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("read_item");

        start_item(item);

        item.op            = i2c_seq_item::I2C_READ;
        item.slave_addr    = 7'h12;
        item.write_data    = 8'h00;
        item.slave_tx_data = slave_data;

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Send READ item: addr=0x%02h slave_tx_data=0x%02h",
                                   item.slave_addr, item.slave_tx_data), UVM_LOW)
    endtask

    task send_write_wrong_addr(bit [6:0] addr, bit [7:0] data);
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("write_wrong_addr_item");

        start_item(item);

        item.op            = i2c_seq_item::I2C_WRITE;
        item.slave_addr    = addr;
        item.write_data    = data;
        item.slave_tx_data = 8'h00;

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Send WRITE WRONG ADDR item: addr=0x%02h data=0x%02h",
                                   item.slave_addr, item.write_data), UVM_LOW)
    endtask


    task send_read_wrong_addr(bit [6:0] addr, bit [7:0] slave_data);
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("read_wrong_addr_item");

        start_item(item);

        item.op            = i2c_seq_item::I2C_READ;
        item.slave_addr    = addr;
        item.write_data    = 8'h00;
        item.slave_tx_data = slave_data;

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Send READ WRONG ADDR item: addr=0x%02h slave_tx_data=0x%02h",
                                   item.slave_addr, item.slave_tx_data), UVM_LOW)
    endtask

    virtual task body();
        `uvm_info("SEQ", "I2C sequence start", UVM_LOW)

        // --------------------------------------------------
        // 1. Target address WRITE patterns
        // cp_write_data bins hit
        // --------------------------------------------------
        send_write(8'h00);  // zero
        send_write(8'hFF);  // ff
        send_write(8'hAA);  // aa
        send_write(8'h55);  // x55
        send_write(8'h3C);  // x3c
        send_write(8'h7E);  // misc

        // --------------------------------------------------
        // 2. Target address READ patterns
        // cp_slave_tx_data bins hit
        // --------------------------------------------------
        send_read(8'h00);  // zero
        send_read(8'hFF);  // ff
        send_read(8'hA5);  // a5
        send_read(8'hC3);  // c3
        send_read(8'h5A);  // x5a
        send_read(8'h7E);  // misc

        // --------------------------------------------------
        // 3. Wrong address test
        // cp_slave_addr.other_addr + NACK hit 목적
        // driver가 item.slave_addr를 실제 주소 전송에 반영해야 함
        // --------------------------------------------------
        send_write_wrong_addr(7'h34, 8'h55);
        send_read_wrong_addr(7'h34, 8'hA5);

        `uvm_info("SEQ", "I2C sequence done", UVM_LOW)
    endtask

endclass
