package ram_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 의존성 순서대로 include 작성
    `include "ram_seq_item.sv"
    `include "ram_sequence.sv"
    `include "ram_driver.sv"
    `include "ram_monitor.sv"
    `include "ram_agent.sv"
    `include "ram_scoreboard.sv"
    `include "ram_coverage.sv"
    `include "ram_env.sv"
    `include "ram_test.sv"
endpackage
