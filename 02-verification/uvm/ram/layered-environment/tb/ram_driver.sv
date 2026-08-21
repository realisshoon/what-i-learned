class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    virtual ram_if r_if;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "virtual interface(vif)를 config_db에서 찾지 못함.")
    endfunction


    task run_phase(uvm_phase phase);
        r_if.drv_cb.we <= 1'b0;
        r_if.drv_cb.addr <= 1'b0;
        r_if.drv_cb.wdata <= 1'b0;
        forever begin
            //내부적으로 req 신호를 만들어줌 누가? uvm 내부에서
            seq_item_port.get_next_item(req);

            @(r_if.drv_cb);  //clocking block 사용 what is this?
            r_if.drv_cb.we    <= req.we;
            r_if.drv_cb.addr  <= req.addr;
            r_if.drv_cb.wdata <= req.wdata;

            `uvm_info(get_type_name(), $sformatf("구동: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask  //

endclass  //ram_base_test extends uvm_test
