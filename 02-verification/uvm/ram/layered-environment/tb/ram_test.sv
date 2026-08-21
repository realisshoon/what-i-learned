class ram_base_test extends uvm_test;
    `uvm_component_utils(ram_base_test)

    ram_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass  //ram_base_test extends uvm_test


class ram_basic_test extends ram_base_test;
    `uvm_component_utils(ram_basic_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    task run_phase(uvm_phase phase);
        ram_wr_rd_seq seq;

        phase.raise_objection(this);

        seq = ram_wr_rd_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_error("TEST", "seq radomize fail")
        seq.start(env.agt.sqr);

        #100;
        phase.drop_objection(this);
    endtask  //
endclass  //ram_basic_test extends ram_base_test



class ram_random_test extends ram_base_test;
    `uvm_component_utils(ram_random_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    task run_phase(uvm_phase phase);
        ram_random_seq seq;

        phase.raise_objection(this);

        seq = ram_random_seq::type_id::create("seq");
        // if (!seq.randomize()) `uvm_error("TEST", "seq radomize fail")
        seq.num = 500;
        seq.start(env.agt.sqr);

        #100;
        phase.drop_objection(this);
    endtask  //
endclass  //ram_basic_test extends ram_base_test
