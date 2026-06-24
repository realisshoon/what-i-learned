`timescale 1ns / 1ps

module tb_i2c_master_slave;

    localparam logic [6:0] SLAVE_ADDR = 7'h12;

    logic       clk;
    logic       rst;

    // Master command
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] master_tx_data;
    logic [7:0] master_rx_data;
    logic       ack_in;
    logic       ack_out;
    logic       busy;
    logic       done;

    // I2C line
    logic       scl;
    wire        sda;

    // Slave side
    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic       slave_rx_done;
    logic       slave_tx_done;
    logic       slave_addr_match;
    logic       slave_rw_mode;
    logic       slave_master_ack;
    logic       slave_busy;

    // I2C SDA pull-up
    pullup (sda);

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Master DUT
    i2c_master_top u_i2c_master_top (
        .clk(clk),
        .rst(rst),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),

        .tx_data(master_tx_data),
        .rx_data(master_rx_data),
        .ack_in (ack_in),
        .ack_out(ack_out),
        .busy   (busy),
        .done   (done),

        .scl(scl),
        .sda(sda)
    );

    // Slave DUT
    i2c_slave_top #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_i2c_slave_top (
        .clk(clk),
        .rst(rst),

        .scl(scl),
        .sda(sda),

        .tx_data(slave_tx_data),

        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done),
        .tx_done(slave_tx_done),

        .addr_match(slave_addr_match),
        .rw_mode   (slave_rw_mode),
        .master_ack(slave_master_ack),
        .busy      (slave_busy)
    );


    task automatic reset_dut();
        begin
            rst            = 1'b1;

            cmd_start      = 1'b0;
            cmd_write      = 1'b0;
            cmd_read       = 1'b0;
            cmd_stop       = 1'b0;

            master_tx_data = 8'd0;
            ack_in         = 1'b1;  // default NACK
            slave_tx_data  = 8'hA5;

            repeat (10) @(posedge clk);
            rst = 1'b0;
            repeat (20) @(posedge clk);

            $display("[%0t] RESET done", $time);
        end
    endtask


    task automatic wait_done_timeout(input string tag, input int max_cycles = 300000);
        int cnt;
        begin
            cnt = 0;

            while ((done !== 1'b1) && (cnt < max_cycles)) begin
                @(posedge clk);
                cnt++;
            end

            if (cnt >= max_cycles) begin
                $error("[%0t] TIMEOUT while waiting done: %s", $time, tag);
                $display("        cmd_start=%0b cmd_write=%0b cmd_read=%0b cmd_stop=%0b",
                         cmd_start, cmd_write, cmd_read, cmd_stop);
                $display("        busy=%0b done=%0b ack_out=%0b scl=%0b sda=%0b", busy, done,
                         ack_out, scl, sda);
                $fatal;
            end

            @(posedge clk);
        end
    endtask


    task automatic clear_cmds();
        begin
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;
        end
    endtask

    task automatic i2c_start();
        begin
            $display("[%0t] CMD START issue", $time);

            @(negedge clk);
            cmd_start <= 1'b1;

            repeat (2) @(negedge clk);
            cmd_start <= 1'b0;

            wait_done_timeout("START");

            $display("[%0t] I2C START done", $time);
        end
    endtask

    // ------------------------------------------------------------
    // I2C WRITE 1 byte
    // Address byte도 Master가 SDA에 쓰는 값이라 이 task 사용
    // ------------------------------------------------------------
    task automatic i2c_write(input logic [7:0] data);
        begin
            $display("[%0t] CMD WRITE issue data=0x%02h", $time, data);

            @(negedge clk);
            master_tx_data <= data;
            cmd_write      <= 1'b1;

            repeat (2) @(negedge clk);
            cmd_write <= 1'b0;

            wait_done_timeout($sformatf("WRITE 0x%02h", data));

            $display("[%0t] I2C WRITE done data=0x%02h ack_out=%0b", $time, data, ack_out);

            if (ack_out !== 1'b0) begin
                $error("[%0t] I2C WRITE NACK detected! data=0x%02h", $time, data);
                $fatal;
            end
        end
    endtask

    // ------------------------------------------------------------
    // I2C READ 1 byte
    // master_ack_value: ACK=0, NACK=1
    // 1byte만 읽고 끝낼 때는 NACK=1
    // ------------------------------------------------------------
    task automatic i2c_read(input logic master_ack_value, output logic [7:0] read_data);
        begin
            $display("[%0t] CMD READ issue ack_in=%0b", $time, master_ack_value);

            @(negedge clk);
            ack_in   <= master_ack_value;
            cmd_read <= 1'b1;

            repeat (2) @(negedge clk);
            cmd_read <= 1'b0;

            wait_done_timeout("READ");

            read_data = master_rx_data;

            $display("[%0t] I2C READ done data=0x%02h master_ack_in=%0b", $time, read_data,
                     master_ack_value);
        end
    endtask

    // ------------------------------------------------------------
    // I2C STOP
    // ------------------------------------------------------------
    task automatic i2c_stop();
        begin
            $display("[%0t] CMD STOP issue", $time);

            @(negedge clk);
            cmd_stop <= 1'b1;

            repeat (2) @(negedge clk);
            cmd_stop <= 1'b0;

            wait_done_timeout("STOP");

            $display("[%0t] I2C STOP done", $time);
        end
    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------
    initial begin
        logic [7:0] read_data;

        $display("========================================");
        $display(" I2C Master-Slave Integration TB Start");
        $display("========================================");

        reset_dut();

        // ========================================================
        // Test 1. Master Write to Slave
        // START -> ADDR+W -> DATA -> STOP
        // ========================================================
        $display("");
        $display("[TEST 1] I2C WRITE TEST");

        i2c_start();

        // Address + Write
        // {7'h12, 1'b0} = 8'h24
        i2c_write({SLAVE_ADDR, 1'b0});

        // Data write
        i2c_write(8'h55);

        i2c_stop();

        repeat (50) @(posedge clk);

        if (slave_rx_data === 8'h55) begin
            $display("[PASS] WRITE TEST: slave_rx_data = 0x%02h", slave_rx_data);
        end else begin
            $error("[FAIL] WRITE TEST: expected 0x55, got 0x%02h", slave_rx_data);
            $fatal;
        end

        // ========================================================
        // Test 2. Master Read from Slave
        // START -> ADDR+R -> READ -> STOP
        // ========================================================
        $display("");
        $display("[TEST 2] I2C READ TEST");

        slave_tx_data = 8'hA5;

        repeat (20) @(posedge clk);

        i2c_start();

        // Address + Read
        // {7'h12, 1'b1} = 8'h25
        i2c_write({SLAVE_ADDR, 1'b1});

        // 1byte만 읽고 끝낼 거라 Master는 NACK 전송
        i2c_read(1'b1, read_data);

        i2c_stop();

        repeat (50) @(posedge clk);

        if (read_data === 8'hA5) begin
            $display("[PASS] READ TEST: master_rx_data = 0x%02h", read_data);
        end else begin
            $error("[FAIL] READ TEST: expected 0xA5, got 0x%02h", read_data);
            $fatal;
        end

        $display("");
        $display("========================================");
        $display(" I2C Master-Slave Integration TB Finish");
        $display("========================================");

        #1000;
        $finish;
    end

endmodule
