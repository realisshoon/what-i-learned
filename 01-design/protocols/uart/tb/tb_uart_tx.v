`timescale 1ns / 1ps

module tb_uart_tx();

    reg clk;
    reg rst;
    reg [7:0] sw;
    reg btnR;
    wire tx;


    uart dut(
        .clk(clk),
        .rst(rst),
        .btnR(btnR),
        .tx_data(sw),
        .tx(tx)
    );
    
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        btnR = 0;
        sw = 8'h00;
    end

    initial begin

        #100;
        rst = 0;
        
        #1000;
        sw = 8'h41;   
        
        btnR = 1;
        #150_000;     
        btnR = 0;
        
        #1_200_000;  
        
        sw = 8'h31;    
        
        #10_000;
        btnR = 1;
        #150_000;     
        btnR = 0;
        
        #1_200_000;    
        
        $finish;
    end
        
endmodule
