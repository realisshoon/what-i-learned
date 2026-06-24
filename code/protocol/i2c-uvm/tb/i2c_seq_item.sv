class i2c_seq_item extends uvm_sequence_item;

    typedef enum logic {
        I2C_WRITE = 1'b0,
        I2C_READ  = 1'b1
    } i2c_op_e;

    rand i2c_op_e       op;
    rand logic    [6:0] slave_addr;
    rand logic    [7:0] write_data;
    rand logic    [7:0] slave_tx_data;

    // monitor가 채워줄 결과값
    logic         [7:0] master_rx_data;
    logic         [7:0] slave_rx_data;

    // Slave ACK 확인용
    // 0 = ACK, 1 = NACK
    logic               slave_ack_received;

    constraint c_slave_addr {soft slave_addr == 7'h12;}

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_enum(i2c_op_e, op, UVM_ALL_ON)
        `uvm_field_int(slave_addr, UVM_ALL_ON)
        `uvm_field_int(write_data, UVM_ALL_ON)
        `uvm_field_int(slave_tx_data, UVM_ALL_ON)
        `uvm_field_int(master_rx_data, UVM_ALL_ON)
        `uvm_field_int(slave_rx_data, UVM_ALL_ON)
        `uvm_field_int(slave_ack_received, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "op=%s addr=0x%02h write_data=0x%02h slave_tx_data=0x%02h master_rx_data=0x%02h slave_rx_data=0x%02h slave_ack_received=%0b",
            (op == I2C_WRITE) ? "WRITE" : "READ",
            slave_addr,
            write_data,
            slave_tx_data,
            master_rx_data,
            slave_rx_data,
            slave_ack_received
        );
    endfunction

endclass
