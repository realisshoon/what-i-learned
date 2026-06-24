class spi_test extends uvm_test;

    `uvm_component_utils(spi_test)

    spi_env env;

    function new(string name = "spi_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = spi_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_base_seq seq;

        phase.raise_objection(this);

        seq = spi_base_seq::type_id::create("seq");

        `uvm_info("TEST", "SPI sequence start", UVM_LOW)

        seq.start(env.agent.sequencer);

        `uvm_info("TEST", "SPI sequence done", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass
