`timescale 1ns / 1ps

module tb_rv32i();
    logic clk, rst;
    
    top_rv32i_soc dut(.*);

    logic [31:0] mem_val_53, mem_val_54, mem_val_55, mem_val_56, mem_val_57;
    assign mem_val_53 = dut.U_DATA_MEM.data_ram[53];
    assign mem_val_54 = dut.U_DATA_MEM.data_ram[54];
    assign mem_val_55 = dut.U_DATA_MEM.data_ram[55];
    assign mem_val_56 = dut.U_DATA_MEM.data_ram[56];
    assign mem_val_57 = dut.U_DATA_MEM.data_ram[57];

    logic [31:0] sp_val;
    assign sp_val = dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.register_file[2];

    logic [31:0] a_val;
    assign a_val = dut.U_DATA_MEM.data_ram[59];

    logic [31:0] ra_val;
    assign ra_val = dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.register_file[1];

    always #5 clk = ~clk;
    initial begin
        $dumpfile("instruction.vcd");
        $dumpvars(0, tb_rv32i);

        clk = 0;
        rst = 1;
        repeat(2) @(negedge clk);
        rst = 0;

        repeat(1500) @(negedge clk);

        $finish;
    end

endmodule
