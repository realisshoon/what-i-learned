class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_if s_if;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if)) begin
            `uvm_fatal(get_type_name(), "virtual interface를 config_db에서 찾지 못함")
        end
    endfunction

    task drive_transfer(spi_seq_item item);
        `uvm_info(get_type_name(), $sformatf(
                                       "Drive SPI tansfer: master_tx = 0x%02h slave_tx =0x%02h",
                                       item.master_tx_data, item.slave_tx_data), UVM_LOW)
        @(s_if.drv_cb);
        s_if.drv_cb.master_tx_data <= item.master_tx_data;
        s_if.drv_cb.slave_tx_data  <= item.slave_tx_data;

        @(s_if.drv_cb);
        s_if.drv_cb.start <= 1'b1;

        @(s_if.drv_cb);
        s_if.drv_cb.start <= 1'b0;

        wait (s_if.drv_cb.master_rx_done == 1'b1);
        wait (s_if.drv_cb.slave_rx_done == 1'b1);

        repeat (5) @(s_if.drv_cb);
    endtask

    task run_phase(uvm_phase phase);
        spi_seq_item item;

        s_if.drv_cb.reset          <= 1'b1;
        s_if.drv_cb.start          <= 1'b0;
        s_if.drv_cb.cpol           <= 1'b0;
        s_if.drv_cb.cpha           <= 1'b0;
        s_if.drv_cb.clk_div        <= 8'd20;
        s_if.drv_cb.master_tx_data <= 8'd0;
        s_if.drv_cb.slave_tx_data  <= 8'd0;

        repeat (5) @(s_if.drv_cb);
        s_if.drv_cb.reset <= 1'b0;
        repeat (5) @(s_if.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);
            drive_transfer(item);
            seq_item_port.item_done();
        end

    endtask  // run_phase(uvm_phase phase);

endclass  //className extends superClass
