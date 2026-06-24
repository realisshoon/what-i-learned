class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent agt;
    ram_scoreboard scb;
    ram_coverage cov;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = ram_agent::type_id::create("agt", this);
        scb = ram_scoreboard::type_id::create("scb", this);
        cov = ram_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction

endclass  //ram_base_test extends uvm_test
