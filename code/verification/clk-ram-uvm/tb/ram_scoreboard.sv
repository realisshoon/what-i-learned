class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)

    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) imp;

    logic [7:0] mem_model[0:2**8-1];
    logic written[256];
    int write_count, read_count = 0;
    int pass_count, fail_count = 0;
    int skipped_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction  //new()

    function void write(ram_seq_item tr);
        if (tr.we) begin
            // 가상의 ram을 생성후 dut를 거친 값과 비교
            write_count++;
            mem_model[tr.addr] = tr.wdata;
            written[tr.addr]   = 1;
        end else begin
            read_count++;
            if (!written[tr.addr]) begin
                skipped_count++;
                return;
            end
            if (tr.rdata === mem_model[tr.addr]) begin
                pass_count++;
                `uvm_info(get_type_name(), $sformatf("PASS: %s (기대값=0x%02h)",
                                                     tr.convert2string(), mem_model[tr.addr]),
                          UVM_HIGH)
            end else begin
                fail_count++;
                `uvm_error(get_type_name(), $sformatf(
                           "FAIL: %s (기대값=0x%02h)", tr.convert2string(), mem_model[tr.addr]))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "====================================", UVM_LOW)
        `uvm_info("SCB", "========SCB 최종 리포트=========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  write count : %0d", write_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  read count : %0d", read_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass count : %0d", pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail count : %0d", fail_count), UVM_LOW)
        `uvm_info("SCB", "==================================", UVM_LOW)
    endfunction

endclass  //ram_base_test extends uvm_test
