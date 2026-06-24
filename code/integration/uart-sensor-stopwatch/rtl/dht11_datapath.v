`timescale 1ns / 1ps

module dht11_datapath (
    input         clk,
    input         rst,
    input         dht11_start,
    output [12:0] data,         // [12:7] : temperature, [6:0] humidity
    inout         dht11
);

    wire w_tick_us, w_valid;
    wire [7:0] w_humidity, w_temperature;

    tick_gen_us U_TICK_GEN_US (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    dht11_controller U_DHT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(dht11_start),
        .tick_us    (w_tick_us),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .valid      (w_valid),        // for check sum 
        .dht11      (dht11)
    );

    dht_to_data U_DHT_TO_DATA (
        .valid      (w_valid),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .data       (data)
    );

endmodule

module dht_to_data (
    input         valid,
    input  [ 7:0] humidity,
    input  [ 7:0] temperature,
    output [12:0] data
);

    assign data = valid ? {temperature[5:0], humidity[6:0]} : 13'd0;


endmodule

module dht11_controller (
    input        clk,
    input        rst,
    input        dht11_start,
    input        tick_us,
    output [7:0] humidity,
    output [7:0] temperature,
    output       valid,        // for check sum 
    inout        dht11
);



    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8, WAIT_HIGH = 9;


    (* mark_debug = "true" *)reg [3:0] c_state;
    reg [3:0] n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  //recieve bit counter 
    reg [$clog2(19_000)-1:0] tick_cnt_reg, tick_cnt_next;  //general tick count
    reg out_sel_reg, out_sel_next;  // dht11 io 3state control
    reg dht11_reg, dht11_next;  //dht11 output drive

    reg [39:0] data_reg, data_next;

    reg dht11_d1, dht11_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dht11_d1 <= 1'b1;
            dht11_d2 <= 1'b1;
        end else begin
            dht11_d1 <= dht11;
            dht11_d2 <= dht11_d1;
        end
    end
    (* mark_debug = "true" *) wire dht11_in = dht11_d2;


    // dht11 output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];


    //checksum 
    assign valid = (data_reg[7:0] == (data_reg[39:32]+data_reg[31:24]+data_reg[23:16]+data_reg[15:8])) ? 1'b1 : 1'b0;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;  // when Idle dht11 output mode
            dht11_reg    <= 1'b1;  // default high state (Idle state)
            data_reg     <= 0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;
            dht11_reg    <= dht11_next;
            data_reg     <= data_next;
        end
    end


    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;

        case (c_state)
            IDLE: begin
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next    = 0;
                    tick_cnt_next   = 0;
                    n_state = START;
                end
            end

            START: begin
                dht11_next   = 1'b0;
                out_sel_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg >= 19_000) begin
                        tick_cnt_next = 0;
                        n_state = WAIT_HIGH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT_HIGH: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end
                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = WAIT;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            WAIT: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end
                if (!dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = SYNCL;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            SYNCL: begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;

                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = SYNCH;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            SYNCH: begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;

                if (!dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            DATA_SYNC: begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;

                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = DATA_COUNT;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            DATA_COUNT: begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;


                if (!dht11_in) begin
                    n_state = DATA_DECISION;
                end else if (tick_cnt_reg > 300) begin
                    n_state = IDLE;
                end
            end

            DATA_DECISION: begin
                out_sel_next = 1'b0;

                data_next = {data_reg[38:0], (tick_cnt_reg > 40) ? 1'b1 : 1'b0};
                bit_cnt_next = bit_cnt_reg + 1;

                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                end else begin
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end
            end

            STOP: begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;

                if (dht11_in) begin
                    n_state = IDLE;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            default: n_state = IDLE;
        endcase
    end

endmodule
