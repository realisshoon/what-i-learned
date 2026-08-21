class ram_base_test extends uvm_test;
    `uvm_component_utils(ram_base_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
    endtask  //

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction

endclass  //ram_base_test extends uvm_test
