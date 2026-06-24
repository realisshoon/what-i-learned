`timescale 1ps / 1ps


module tb_i2c_master ();
    localparam SLA = 8'h12;

    logic       clk;
    logic       reset;
    // command port
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    // internal port
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;  // read 시 master가 보낼 ACK(0)/NACK(1)
    logic       ack_out;  // write 시 slave로부터 받은 ACK(0)/NACK(1)
    logic       busy;
    logic       done;
    // external i2c port
    logic       scl;
    wire        sda;

    logic       sda_slave_drive_low;

    assign sda = sda_slave_drive_low ? 1'b0 : 1'bz;
    pullup (scl);
    pullup (sda);

    initial clk = 0;
    always #5 clk = ~clk;

    I2C_Master_top dut (.*);


    task automatic slave_ack_once();
        begin
            sda_slave_drive_low = 1'b0;

            repeat (8) @(posedge scl);
            @(negedge scl);

            sda_slave_drive_low = 1'b1;

            @(posedge scl);

            @(negedge scl);
            sda_slave_drive_low = 1'b0;
        end
    endtask  //automatic

    task i2c_write(byte data);
        // data write

        tx_data = data;  // 8'h12 << 1 | 1'b0, write

        fork
            slave_ack_once();
        join_none

        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        cmd_write = 1'b0;

        wait (done);
        @(posedge clk);
    endtask

    task i2c_start();
        begin
            cmd_start = 1'b1;
            cmd_write = 1'b0;
            cmd_read  = 1'b0;
            cmd_stop  = 1'b0;

            @(posedge clk);
            cmd_start = 1'b0;

            wait (done);
            @(posedge clk);
        end
    endtask

    task i2c_stop();
        begin
            cmd_start = 1'b0;
            cmd_write = 1'b0;
            cmd_read  = 1'b0;
            cmd_stop  = 1'b1;

            @(posedge clk);
            cmd_stop = 1'b0;

            wait (done);
            @(posedge clk);
        end
    endtask

    initial begin
        reset = 1'b1;
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;

        tx_data = 8'd0;
        ack_in = 1'b1;
        sda_slave_drive_low = 1'b0;

        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (5) @(posedge clk);

        i2c_start();


        i2c_write({SLA, 1'b0});
        i2c_write(8'h55);
        i2c_stop();

        // IDLE
        #100;
        $finish;

    end
endmodule
