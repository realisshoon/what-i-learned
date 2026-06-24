class ram_coverage extends uvm_subscriber #(ram_seq_item);
    `uvm_component_utils(ram_coverage)

    ram_seq_item tr;

    covergroup ram_cg;
        cp_op: coverpoint tr.we {bins read = {0}; bins write = {1};}
        cp_addr: coverpoint tr.addr {
            bins addr_min = {8'h00};
            bins addr_low1 = {[8'h01 : 8'h20]};
            bins addr_low2 = {[8'h21 : 8'h54]};
            bins addr_mid1 = {[8'h55 : 8'h70]};
            bins addr_mid2 = {[8'h71 : 8'hAA]};
            bins addr_high1 = {[8'hAB : 8'hC0]};
            bins addr_high2 = {[8'hC1 : 8'hFE]};
            bins addr_max = {8'hff};
        }
        cp_wdata: coverpoint tr.wdata iff (tr.we) {
            bins data_zero = {8'h00}; bins data_max = {8'hFF}; bins data_etc = {[8'h01 : 8'hFE]};
        }
        cx_op_addr : cross cp_op, cp_addr;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ram_cg = new();
    endfunction  //new()

    function void write(ram_seq_item t);
        tr = t;
        ram_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "==============================", UVM_LOW)
        `uvm_info("COV", "===Functional Coverage 결과===", UVM_LOW)
        `uvm_info("COV", $sformatf("     전체      : %6.2f %%", ram_cg.get_inst_coverage()),
                  UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "     동작 종류  : %6.2f %%(read/write)", ram_cg.cp_op.get_inst_coverage()),
                  UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "     주소      : %6.2f %%(read/write)", ram_cg.cp_op.get_inst_coverage()),
                  UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "     데이터  : %6.2f %%(read/write)", ram_cg.cp_wdata.get_inst_coverage()),
                  UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            "     동작x주소  : %6.2f %%(read/write)", ram_cg.cx_op_addr.get_inst_coverage()),
            UVM_LOW)
        `uvm_info("COV", "==============================", UVM_LOW)

        if (ram_cg.get_inst_coverage() < 100.0) begin
            `uvm_warning(
                "COV",
                "커버리지 100% 미달! 시나리오를 추가하거나 더 테스트를 진행하셈;")
        end
    endfunction
endclass  //ram_base_test extends uvm_test
