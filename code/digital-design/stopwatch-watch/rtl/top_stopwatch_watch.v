`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input rst,
    input btnR,
    input btnL,
    input btnD,
    input btnU,

    input  [2:0] sw,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [1:0] led
);

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    // --------------------------------------------------
    // 1. 와이어 선언
    // --------------------------------------------------
    wire w_btnR, w_btnL, w_btnD, w_btnU;

    // button_router용 와이어
    wire sw_stop_btnR, sw_stop_btnL, sw_stop_btnU, sw_stop_btnD;

    // 스톱워치용 와이어
    wire [MSEC_WIDTH-1:0] w_sw_msec;
    wire [ SEC_WIDTH-1:0] w_sw_sec;
    wire [ MIN_WIDTH-1:0] w_sw_min;
    wire [HOUR_WIDTH-1:0] w_sw_hour;
    wire w_mode, w_clear, w_run_stop;

    // 시계용 와이어
    wire [           1:0] w_watch_state;
    wire [MSEC_WIDTH-1:0] w_watch_msec;
    wire [ SEC_WIDTH-1:0] w_watch_sec;
    wire [ MIN_WIDTH-1:0] w_watch_min;
    wire [HOUR_WIDTH-1:0] w_watch_hour;

    // MUX용 와이어 (FND로 갈 최종 데이터)
    wire [MSEC_WIDTH-1:0] mux_msec;
    wire [ SEC_WIDTH-1:0] mux_sec;
    wire [ MIN_WIDTH-1:0] mux_min;
    wire [HOUR_WIDTH-1:0] mux_hour;



    // --------------------------------------------------
    // 2. 입력 제어부 (디바운스 + 라우터 통합 래퍼)
    // --------------------------------------------------
    input_controller U_INPUT_CTRL (
        .clk       (clk),
        .rst       (rst),
        .sw2_enable(sw[2]),
        .btnR      (btnR),
        .btnL      (btnL),
        .btnD      (btnD),
        .btnU      (btnU),
        .wt_btnR   (w_btnR),
        .wt_btnL   (w_btnL),
        .wt_btnD   (w_btnD),
        .wt_btnU   (w_btnU),
        .sw_btnR   (sw_stop_btnR),
        .sw_btnL   (sw_stop_btnL),
        .sw_btnD   (sw_stop_btnD),
        .sw_btnU   (sw_stop_btnU)
    );

    // --------------------------------------------------
    // 3. 스톱워치 도메인
    // --------------------------------------------------
    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk       (clk),
        .rst       (rst),
        .i_mode    (sw_stop_btnD), 
        .i_clear   (sw_stop_btnL),
        .i_run_stop(sw_stop_btnR),
        .i_btnu    (sw_stop_btnU),
        .o_mode    (w_mode),
        .o_clear   (w_clear),
        .o_run_stop(w_run_stop)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .i_run_stop(w_run_stop),
        .msec      (w_sw_msec),
        .sec       (w_sw_sec),
        .min       (w_sw_min),
        .hour      (w_sw_hour)
    );


    // --------------------------------------------------
    // 4. 시계 (Watch) 도메인 추가!
    // --------------------------------------------------
    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .sw(sw[2]),  // sw[2]==1 이면 시계 FSM은 NORMAL 고정(차단)
        .i_btnL(w_btnL),
        .i_btnR(w_btnR),
        .o_state(w_watch_state)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk        (clk),
        .rst        (rst),
        .i_state    (w_watch_state),
        .i_btnU_tick(w_btnU),
        .i_btnD_tick(w_btnD),
        .o_msec     (w_watch_msec),
        .o_sec      (w_watch_sec),
        .o_min      (w_watch_min),
        .o_hour     (w_watch_hour)
    );

    // --------------------------------------------------
    // 5. 통합 FND 디스플레이 제어 (모든 데이터를 다 보냄)
    // --------------------------------------------------
    fnd_controller U_FND_CNTL (
        .clk    (clk),
        .rst    (rst),
        .sw     (sw[1:0]),
        .i_state(w_watch_state),

        // 스톱워치 데이터 다이렉트 연결
        .sw_msec(w_sw_msec),
        .sw_sec (w_sw_sec),
        .sw_min (w_sw_min),
        .sw_hour(w_sw_hour),

        // 시계 데이터 다이렉트 연결
        .wt_msec(w_watch_msec),
        .wt_sec (w_watch_sec),
        .wt_min (w_watch_min),
        .wt_hour(w_watch_hour),

        .fnd_data(fnd_data),
        .fnd_com (fnd_com)
    );

    // LED 표시
    assign led[0] = sw[0];
    assign led[1] = sw[2];




endmodule
