`timescale 1ns / 1ps


module tb_uart();

// system clock * 1clock time / BAUD 
parameter UART_1BAUD_PERIOD= 100_000_000*10/9600;   // 100us -> 10kbps baudrate

reg        clk;
reg        rst;
reg        btnR;
reg  [7:0] tx_data;
wire       tx;

uart dut(
    .clk     (clk),
    .rst     (rst),
    .btnR    (btnR),
    .tx_data (tx_data),
    .tx      (tx)
);



    always #5 clk = ~ clk;
    initial begin
        clk = 0;
        rst = 1;
        btnR = 0;
        tx_data = 8'h30;    // ASCII : 0

        // rst 
        @(negedge clk);
        @(negedge clk);

        rst = 0;

        //button push btnR
        // tx start trigger
        btnR = 1;
        #(100_000)
        btnR = 0;

        repeat(10) #(UART_1BAUD_PERIOD);
        
        #100;
        // change data
        btnR=  1; 
        tx_data = 8'h42;    // ASCII : B
        #(100_000)
        btnR = 0;

        repeat(10) #(UART_1BAUD_PERIOD);





        #100;
        $stop;
    end

endmodule
