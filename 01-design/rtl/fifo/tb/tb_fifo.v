`timescale 1ns / 1ps

module tb_fifo ();

    parameter DEPTH = 4;

    reg clk;
    reg rst;
    reg [7:0] push_data;
    reg push;
    reg pop;
    wire [7:0] pop_data;
    wire empty;
    wire full;

    //random verification
    reg [7:0] compare_data[0:DEPTH-1];
    reg [1:0] push_cnt, pop_cnt;


    fifo dut (
        .clk(clk),
        .rst(rst),
        .push_data(push_data),
        .push(push),
        .pop(pop),
        .pop_data(pop_data),
        .empty(empty),
        .full(full)
    );


    always #5 clk = ~clk;
    integer i;


    initial begin
        clk = 0;
        rst = 1;
        push_data = 0;
        push = 0;
        pop = 0;

        //reset
        #10 rst = 0;


        @(posedge clk);
        #1;

        // push only 
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            push = 1'b1;
            push_data = i;
            #10;
        end

        #10;
        push = 1'b0;

        // pop only
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1'b1;
            #10;
        end


        push = 1;
        pop = 0;
        push_data = 8'h30;
        #10

        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1'b1;
            push_data = i + 8'h30;
            #10;
        end
        //empty fifo for random test

        pop  = 1;
        push = 0;
        #20;

        pop  = 0;
        push = 0;
        #20;
        // random test 
        push_cnt = 0;
        pop_cnt  = 0;

        // syncronize for drive signal
        @(posedge clk);
        for (i = 0; i < 16; i = i + 1) begin
            // randomize
            #1;
            push = $random % 2;
            pop = $random % 2;
            push_data = $random % 256;
            // compare data saving
            if ((push) && (!full)) begin
                compare_data[push_cnt] = push_data;
                push_cnt = push_cnt + 1;
            end
            @(negedge clk);
            if ((pop) && (!empty)) begin
                // compare
                if (pop_data == compare_data[pop_cnt]) begin
                    $display("%t : pass : popdata = %h, compare_data = %h",
                            $time, pop_data, compare_data[pop_cnt]);
                end else begin
                    $display("%t : fail : popdata = %h, compare_data = %h",
                            $time, pop_data, compare_data[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
            @(posedge clk);
        end




        #100;
        $stop;

    end


endmodule
