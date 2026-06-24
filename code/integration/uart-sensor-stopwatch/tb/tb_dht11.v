`timescale 1ns / 1ps

module tb_dht11();

    reg clk;
    reg rst;
    reg dht11_start;

    wire [12:0] data; // dht11_datapath 출력

    tri1 dht11_pin;     
    reg  dht11_drv;      
    reg  dht11_out;     
    assign dht11_pin = dht11_drv ? dht11_out : 1'bz;

    dht11_datapath dut (
        .clk(clk),
        .rst(rst),
        .dht11_start(dht11_start),
        .data(data),
        .dht11(dht11_pin)
    );

    always #5 clk = ~clk;

    reg [39:0] test_data = 40'h2D_00_19_00_46;
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        dht11_start = 0;
        dht11_drv = 0; 
        dht11_out = 0;
        
        #100;
        rst = 0;
        #1000;

        dht11_start = 1;
        #20;
        dht11_start = 0;

        wait(dht11_pin === 1'b0); 
        $display("[%0t] Master Start Signal Detected (LOW)", $time);
        
        wait(dht11_pin === 1'b1); 
        $display("[%0t] Master Released Bus (HIGH)", $time);
        
        #20000; 
        dht11_drv = 1;
        dht11_out = 0;
        #80000; 
        
        dht11_out = 1;
        #80000; 

        $display("[%0t] Sensor Data Transmission Start", $time);
        for (i = 39; i >= 0; i = i - 1) begin
            dht11_out = 0;
            #50000; 

            dht11_out = 1;
            if (test_data[i] == 1'b0) begin
                #26000;
            end else begin
                #70000;
            end
        end

        dht11_out = 0;
        #50000;
        dht11_drv = 0; 
        $display("[%0t] Sensor Data Transmission End", $time);

        #100000; 
        
        // 데이터 확인 로직
        // data[12:7] = 온도(25), data[6:0] = 습도(45)
        if (data != 13'd0) begin
            $display("========================================");
            $display("SUCCESS! Data Extraction Valid.");
            $display("Humidity: %d %%, Temperature: %d C", data[6:0], data[12:7]);
            $display("========================================");
        end else begin
            $display("========================================");
            $display("FAIL! Data is 0. Checksum might be invalid.");
            $display("Expected Temperature: 25, Humidity: 45");
            $display("========================================");
        end


        #10000;
        $finish;
    end

endmodule
