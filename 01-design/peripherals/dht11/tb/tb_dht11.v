`timescale 1ns / 1ps
module tb_dht11 ();
    // 시뮬레이션 파라미터
    parameter [7:0] HUMI_INT = 8'd60;  // 습도 정수부
    parameter [7:0] TEMP_INT = 8'd25;  // 온도 정수부
    parameter [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };
    reg clk;
    reg rst;
    reg btn_start;

    // 
    reg dht_sensor_data;
    reg io_oe;

    wire [5:0] led;
    wire dht11; // force 

    //  tb io mode 변환.
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;


    dht11_controller dut (
        .clk(clk),
        .rst(rst),
        .btn_start(btn_start),
        .led(led),
        .dht11(dht11)  // inout port
    );
    always #5 clk = ~clk;
    integer i = 0;

    initial begin
        clk = 0;
        rst = 1;
        io_oe = 0;
        btn_start = 0;

        #100;
        rst = 0;
        #100;
        btn_start = 1;
        #100;
        btn_start = 0;
        #100;
        wait (!dht11);
        // 18msec 대기
        wait (dht11);
        #30000;
        // 입력 모드로 변환 x가 발생할수도있음
        io_oe = 1;
        dht_sensor_data = 1'b0;
        #80000;
        dht_sensor_data = 1'b1;
        #80000;
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0;
            #50000;
            dht_sensor_data = 1'b1;
            #(DATA_STREAM[i] ? 70000 : 26000);

        end
        dht_sensor_data = 0;
        #50000;
        io_oe = 0;
        #50000;
        $stop;
    end




endmodule
