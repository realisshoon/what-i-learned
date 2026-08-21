`timescale 1ns / 1ps

module sr04_datapath(
    input clk,
    input rst,
    input sr04_start,
    input echo,
    output trig,
    output [12:0] data
);

    wire w_tick_us;
    wire [8:0] w_distance;

    sr04_controller U_SR04_CNTL(
    .clk(clk),
    .rst(rst),
    .tick_us(w_tick_us),
    .sr04_start(sr04_start),
    .echo(echo),
    .trig(trig),
    .distance(w_distance)
);

    distance_to_data U_DISTANCE_TO_DATA(
    .distance(w_distance),
    .data(data) // [6:0] 1digit, 10digit, [13:7] 100digit
);

    tick_gen_us U_TICK_GEN_US(
    .clk(clk),
    .rst(rst),
    .tick_us(w_tick_us)
);

endmodule

module distance_to_data(
    input [8:0] distance,
    output [12:0] data // [6:0] 1digit, 10digit, [13:7] 100digit
);

    assign data [6:0] = distance % 100;
    assign data [12:7] = (distance / 100) % 10;

endmodule

module top_sr04_controller (
    input        clk,
    input        rst,
    input        btn_R,
    input        echo,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_sr04_start;
    wire [8:0] w_distance;
    wire w_tick_us;

    ila_0 U_ILA0 (
        .clk(clk),
        .probe0(echo),
        .probe1(w_distance)
    );

    button_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_R),
        .o_btn(w_sr04_start)
    );

    fnd_controller U_FND_CTRL (
        .clk(clk),
        .rst(rst),
        .fnd_in({{5'b00000}, w_distance}),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    tick_gen_us U_TICK_GEN_US (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    sr04_controller U_SR04_CNTL (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us),
        .sr04_start(w_sr04_start),
        .echo(echo),
        .trig(trig),
        .distance(w_distance)
    );

endmodule

module sr04_controller (
    input        clk,
    input        rst,
    input        tick_us,
    input        sr04_start,
    input        echo,
    output       trig,
    output [8:0] distance
);

    parameter IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;
    parameter START_WIDTH = 11;

    reg [1:0] c_state, n_state;
    reg trig_reg, trig_next;
    reg [3:0] start_cnt_reg, start_cnt_next;
    reg [5:0] echo_cnt_reg, echo_cnt_next;
    reg [8:0] distance_reg, distance_next;


    assign distance = distance_reg;
    assign trig = trig_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            trig_reg <= 0;
            start_cnt_reg <= 0;
            echo_cnt_reg <= 0;
            distance_reg <= 0;
        end else begin
            c_state <= n_state;
            trig_reg <= trig_next;
            start_cnt_reg <= start_cnt_next;
            echo_cnt_reg <= echo_cnt_next;
            distance_reg <= distance_next;
        end
    end


    always @(*) begin
        n_state = c_state;
        trig_next = trig_reg;
        start_cnt_next = start_cnt_reg;
        echo_cnt_next = echo_cnt_reg;
        distance_next = distance_reg;
        case (c_state)
            IDLE: begin
                if (sr04_start) begin
                    n_state = START;
                end
            end
            START: begin
                trig_next = 1'b1;
                if (tick_us) begin
                    if (start_cnt_reg == START_WIDTH - 1) begin
                        n_state = WAIT;
                        start_cnt_next = 0;
                        trig_next = 1'b0;
                        distance_next = 0;
                    end else begin
                        start_cnt_next = start_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (echo == 1) begin
                    n_state = RESPONSE;
                end
            end
            RESPONSE: begin
                if (echo == 1) begin
                    if (tick_us) begin
                        if (distance_reg == 400) begin
                            echo_cnt_next = 0;
                            n_state = IDLE;
                        end else begin
                            if (echo_cnt_reg == 57) begin  // 58us = 1 centimeter
                                distance_next = distance_reg + 1;
                                echo_cnt_next = 0;
                            end else begin
                                echo_cnt_next = echo_cnt_reg + 1;
                            end
                        end
                    end
                end else begin
                    if (echo == 0) begin
                        echo_cnt_next = 0;
                        n_state = IDLE;
                    end
                end
            end
        endcase
    end

endmodule

module tick_gen_us (
    input clk,
    input rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;

    reg [$clog2(F_COUNT) - 1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_us <= 1'b0;
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us <= 1'b1;
            end else tick_us = 1'b0;
        end
    end

endmodule
