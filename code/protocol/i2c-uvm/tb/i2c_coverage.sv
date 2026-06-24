class i2c_coverage extends uvm_subscriber #(i2c_seq_item);

    `uvm_component_utils(i2c_coverage)

    i2c_seq_item item;

    covergroup i2c_cg;
        option.per_instance = 1;  // coverage instance 별로 계산

        cp_op: coverpoint item.op {
            bins write = {i2c_seq_item::I2C_WRITE}; bins read = {i2c_seq_item::I2C_READ};
        }

        cp_slave_addr: coverpoint item.slave_addr {
            bins target_addr = {7'h12}; bins other_addr = default;
        }

        cp_write_data: coverpoint item.write_data iff (item.op == i2c_seq_item::I2C_WRITE) {
            bins zero = {8'h00};
            bins ff = {8'hFF};
            bins aa = {8'hAA};
            bins x55 = {8'h55};
            bins x3c = {8'h3C};
            bins misc = default;
        }

        cp_slave_tx_data: coverpoint item.slave_tx_data iff (item.op == i2c_seq_item::I2C_READ) {
            bins zero = {8'h00};
            bins ff = {8'hFF};
            bins a5 = {8'hA5};
            bins c3 = {8'hC3};
            bins x5a = {8'h5A};
            bins misc = default;
        }


        cp_ack: coverpoint item.slave_ack_received {bins ack = {1'b0}; bins nack = {1'b1};}

        // WRITE transaction:
        // ADDR + W 이후 어떤 data를 보냈는지 확인
        cross_write_addr_data: cross cp_op, cp_slave_addr, cp_write_data{
            ignore_bins not_write = binsof (cp_op.read);
        }

        // READ transaction:
        // ADDR + R 이후 어떤 slave_tx_data를 읽었는지 확인
        cross_read_addr_data: cross cp_op, cp_slave_addr, cp_slave_tx_data{
            ignore_bins not_read = binsof (cp_op.write);
        }

    endgroup

    function new(string name = "i2c_coverage", uvm_component parent = null);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    virtual function void write(i2c_seq_item t);
        item = t;
        i2c_cg.sample();

        `uvm_info("COV", $sformatf("Sample coverage: %s", item.convert2string()), UVM_MEDIUM)
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COV", "========================================", UVM_NONE)
        `uvm_info("COV", $sformatf(
                  "Final I2C functional coverage = %0.2f%%", i2c_cg.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", "========================================", UVM_NONE)
    endfunction

endclass
