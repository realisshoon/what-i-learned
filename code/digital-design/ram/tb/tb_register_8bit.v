`timescale 1ns / 1ps

module tb_register_8bit(

);


    reg             clk;
    reg             rst;
    reg     [7:0]   d;
    wire    [7:0]   q;


    register_8bit dut(
        .clk(clk),
        .rst(rst),
        .d(d),
        .q(q)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        rst = 1;
        d = 8'h00;
        #10;
        rst = 0;



        @(posedge clk);
        #1;
        for (i = 0; i < 256; i=i+1) begin
            d=i;
            @(posedge clk);
            #1;
        end

            @(posedge clk);
            $stop;

    end




endmodule
