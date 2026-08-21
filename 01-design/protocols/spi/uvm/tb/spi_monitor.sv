class spi_monitor extends uvm_component;

    `uvm_component_utils(spi_monitor)

    virtual spi_if s_if;

    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name = "spi_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if)) begin
            `uvm_fatal("MON", "Failed to get virtual interface")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_seq_item item;

        forever begin
            // transaction 시작 감지
            wait (s_if.mon_cb.start == 1'b1);

            item = spi_seq_item::type_id::create("item");

            // 입력값 캡처
            item.master_tx_data = s_if.mon_cb.master_tx_data;
            item.slave_tx_data = s_if.mon_cb.slave_tx_data;

            `uvm_info("MON", $sformatf(
                      "Transaction start: master_tx=0x%02h slave_tx=0x%02h",
                      item.master_tx_data,
                      item.slave_tx_data
                      ), UVM_LOW)

            // 전송 완료 대기
            wait (s_if.mon_cb.master_rx_done == 1'b1);
            wait (s_if.mon_cb.slave_rx_done == 1'b1);

            // done 뜬 다음 안정적으로 1클럭 뒤 샘플
            @(s_if.mon_cb);

            item.master_rx_data = s_if.mon_cb.master_rx_data;
            item.slave_rx_data  = s_if.mon_cb.slave_rx_data;

            `uvm_info(get_type_name(), $sformatf(
                      "Transaction done: master_rx=0x%02h slave_rx=0x%02h",
                      item.master_rx_data,
                      item.slave_rx_data
                      ), UVM_LOW)

            // scoreboard로 transaction 전달
            ap.write(item);

            // start가 내려갈 시간 확보
            repeat (2) @(s_if.mon_cb);
        end
    endtask

endclass
