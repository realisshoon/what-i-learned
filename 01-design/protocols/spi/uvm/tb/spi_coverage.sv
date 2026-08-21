class spi_coverage extends uvm_subscriber #(spi_seq_item);

    `uvm_component_utils(spi_coverage)

    logic [7:0] cov_master_tx_data;
    logic [7:0] cov_slave_tx_data;
    logic       cov_m2s_match;
    logic       cov_s2m_match;

    covergroup spi_cg;
        option.per_instance = 1;

        cp_master_tx: coverpoint cov_master_tx_data {
            bins zero = {8'h00};
            bins all_one = {8'hFF};
            bins pat_aa = {8'hAA};
            bins pat_55 = {8'h55};
            bins low = {[8'h01 : 8'h3F]};
            bins mid = {[8'h40 : 8'hBF]};
            bins high = {[8'hC0 : 8'hFE]};
        }

        cp_slave_tx: coverpoint cov_slave_tx_data {
            bins zero = {8'h00};
            bins all_one = {8'hFF};
            bins pat_aa = {8'hAA};
            bins pat_55 = {8'h55};
            bins low = {[8'h01 : 8'h3F]};
            bins mid = {[8'h40 : 8'hBF]};
            bins high = {[8'hC0 : 8'hFE]};
        }

        cp_m2s_match: coverpoint cov_m2s_match {bins pass = {1'b1}; bins fail = {1'b0};}

        cp_s2m_match: coverpoint cov_s2m_match {bins pass = {1'b1}; bins fail = {1'b0};}

        cross_tx_pattern: cross cp_master_tx, cp_slave_tx;

    endgroup

    function new(string name = "spi_coverage", uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    virtual function void write(spi_seq_item t);

        cov_master_tx_data = t.master_tx_data;
        cov_slave_tx_data = t.slave_tx_data;

        cov_m2s_match = (t.slave_rx_data === t.master_tx_data);
        cov_s2m_match = (t.master_rx_data === t.slave_tx_data);

        spi_cg.sample();

        `uvm_info("COV", $sformatf(
                  "Sample coverage: master_tx=0x%02h slave_tx=0x%02h m2s_match=%0d s2m_match=%0d coverage=%0.2f%%",
                  cov_master_tx_data,
                  cov_slave_tx_data,
                  cov_m2s_match,
                  cov_s2m_match,
                  spi_cg.get_inst_coverage()
                  ), UVM_LOW)

    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COV", $sformatf(
                  "Final SPI functional coverage = %0.2f%%", spi_cg.get_inst_coverage()), UVM_NONE)
    endfunction

endclass
