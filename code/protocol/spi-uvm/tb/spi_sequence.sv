class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)
    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction  //new()


    virtual task body();
        spi_seq_item item;

        // Directed test 1: AA <-> 55
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.master_tx_data = 8'hAA;
        item.slave_tx_data  = 8'h55;
        finish_item(item);

        // Directed test 2: FF <-> 00
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.master_tx_data = 8'hFF;
        item.slave_tx_data  = 8'h00;
        finish_item(item);

        // Directed test 3: 00 <-> FF
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.master_tx_data = 8'h00;
        item.slave_tx_data  = 8'hFF;
        finish_item(item);

        // Directed test 4: 3C <-> C3
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.master_tx_data = 8'h3C;
        item.slave_tx_data  = 8'hC3;
        finish_item(item);

        // Random test
        repeat (20) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);

            if (!item.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end

            `uvm_info("SEQ", $sformatf(
                      "Random item: master_tx=0x%02h slave_tx=0x%02h",
                      item.master_tx_data,
                      item.slave_tx_data
                      ), UVM_LOW)

            finish_item(item);
        end
    endtask
endclass  //className extends superClass
