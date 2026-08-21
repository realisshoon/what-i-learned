`timescale 1ns / 1ps

module watch_datapath_new #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input         clk,
    input         rst,
    input         i_digit,
    input         i_up_down,
    input  [ 2:0] i_sel,
    output [23:0] time_data
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    watch_tick_counter #(
        .TIME_60(24),
        .TIME_10(10),
        .BIT_WIDTH(HOUR_WIDTH),
        .INITIAL_TIME(12)
    ) U_WATCH_HOUR_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_hour_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[2]),
        .time_counter(hour),
        .o_tick      ()
    );

    watch_tick_counter #(
        .TIME_60(60),
        .TIME_10(10),
        .BIT_WIDTH(MIN_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_MIN_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_min_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[1]),
        .time_counter(min),
        .o_tick      (w_hour_tick)
    );

    watch_tick_counter #(
        .TIME_60(60),
        .TIME_10(10),
        .BIT_WIDTH(SEC_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_SEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_sec_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[0]),
        .time_counter(sec),
        .o_tick      (w_min_tick)
    );

    watch_tick_counter #(
        .TIME_60(100),
        .TIME_10(10),
        .BIT_WIDTH(MSEC_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_MSEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_tick_100hz),
        .i_digit     (),
        .i_up_down   (),
        .i_sel       (),
        .time_counter(msec),
        .o_tick      (w_sec_tick)
    );

    watch_tick_gen_100hz U_WATCH_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input         clk,
    input         rst,
    input         i_digit,
    input         i_up_down,
    input  [ 2:0] i_sel,
    output [23:0] data
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    wire [MSEC_WIDTH - 1:0] w_msec;
    wire [ SEC_WIDTH - 1:0] w_sec;
    wire [ MIN_WIDTH - 1:0] w_min;
    wire [HOUR_WIDTH - 1:0] w_hour;

    assign data = {w_hour, w_min, w_sec, w_msec};

    watch_tick_counter #(
        .TIME_60(24),
        .TIME_10(10),
        .BIT_WIDTH(HOUR_WIDTH),
        .INITIAL_TIME(12)
    ) U_WATCH_HOUR_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_hour_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[2]),
        .time_counter(w_hour),
        .o_tick      ()
    );

    watch_tick_counter #(
        .TIME_60(60),
        .TIME_10(10),
        .BIT_WIDTH(MIN_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_MIN_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_min_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[1]),
        .time_counter(w_min),
        .o_tick      (w_hour_tick)
    );

    watch_tick_counter #(
        .TIME_60(60),
        .TIME_10(10),
        .BIT_WIDTH(SEC_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_SEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_sec_tick),
        .i_digit     (i_digit),
        .i_up_down   (i_up_down),
        .i_sel       (i_sel[0]),
        .time_counter(w_sec),
        .o_tick      (w_min_tick)
    );

    watch_tick_counter #(
        .TIME_60(100),
        .TIME_10(10),
        .BIT_WIDTH(MSEC_WIDTH),
        .INITIAL_TIME(0)
    ) U_WATCH_MSEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_tick_100hz),
        .i_digit     (),
        .i_up_down   (),
        .i_sel       (),
        .time_counter(w_msec),
        .o_tick      (w_sec_tick)
    );

    watch_tick_gen_100hz U_WATCH_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module watch_tick_counter #(
    parameter TIME_60 = 60,  // overflow time
    TIME_10 = 10,
    BIT_WIDTH = 7,
    INITIAL_TIME = 0
) (
    input                          clk,
    input                          rst,
    input                          i_tick,
    input                          i_digit,
    input                          i_up_down,
    input                          i_sel,
    output     [BIT_WIDTH - 1 : 0] time_counter,
    output reg                     o_tick

);

    // counter register
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= INITIAL_TIME;
        end else begin
            counter_reg <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            counter_next = counter_reg + 1;
            if (counter_reg == TIME_60 - 1) begin
                o_tick = 1'b1;
                counter_next = 0;
            end else begin
                o_tick = 1'b0;
            end
        end else if (i_sel) begin
            case ({
                i_digit, i_up_down
            })
                2'b00: begin
                    if (TIME_60 == 24) begin
                        if (counter_reg > 13) counter_next = counter_reg % 10;
                        else counter_next = counter_reg + 10;
                    end else begin
                        if (counter_reg == TIME_60 - 1) begin
                            counter_next = 9;
                        end else begin
                            if (counter_reg + 10 < TIME_60)
                                counter_next = counter_reg + 10;
                            else begin
                                counter_next = (counter_reg + 10) % (TIME_60);
                            end
                        end
                    end
                    //if (counter_next > TIME_60 - TIME_10 - 1) begin
                    //    counter_next = (counter_reg + 10) % TIME_60;
                    //end else counter_next = counter_reg + 10;
                end
                2'b01: begin
                    if (counter_next < TIME_10) begin
                        counter_next = TIME_60 - (TIME_10 - counter_reg);
                    end else counter_next = counter_reg - 10;
                end
                2'b10: begin
                    if (counter_next == TIME_60 - 1) begin
                        counter_next = 0;
                    end else counter_next = counter_reg + 1;

                end
                2'b11: begin
                    if (counter_next == 0) begin
                        counter_next = TIME_60 - 1;
                    end else counter_next = counter_reg - 1;
                end
            endcase
        end
    end


endmodule

// tick gen 100hz
module watch_tick_gen_100hz (
    input      clk,
    input      rst,
    output reg o_tick_100hz
);
    // 100 Hz counter number
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg  <= 0;
                o_tick_100hz <= 1'b1;
            end else begin
                o_tick_100hz <= 1'b0;
            end
        end
    end
endmodule
