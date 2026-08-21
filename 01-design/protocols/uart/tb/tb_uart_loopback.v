`timescale 1ns / 1ps



module tb_uart_loopback();
    
    parameter BAUD_DELAY = 2_000;
    parameter BAUD_PERIOD = ((100_000_000/9600) * 10) - BAUD_DELAY;

    reg [7:0] compare_data;
    reg clk, rst, rx;
    wire tx;

    
uart_loopback dut (
    .clk       (clk),
    .rst       (rst),
    .rx        (rx),
    .tx        (tx)
);


always #5 clk = ~clk;


integer  i, j;

task SENDER_UART(input [7:0] send_data);
    begin
        // pc tx
        // start
        rx = 0;

        // start bit
        #(BAUD_PERIOD);
        // data bit
        for ( i=0 ; i<8 ; i=i+1) begin
            // rx, sedn_data[0]~[7]
            rx = send_data[i];
            #(BAUD_PERIOD);
        end
        // stop bit
        rx = 1;
        #(BAUD_PERIOD);
    end
endtask

initial begin
    clk = 0;
    rst = 1;
    rx  = 1;

    @(negedge clk);
    @(negedge clk);

    rst = 0;
    
    #(BAUD_PERIOD*2);

    for (j = 0; j < 12; j = j + 1) begin
        SENDER_UART(8'h30 + j);
    end

    #(BAUD_PERIOD*20);
    #1000;
    $stop;

end



endmodule
