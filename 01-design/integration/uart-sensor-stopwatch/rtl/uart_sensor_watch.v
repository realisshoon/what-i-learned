`timescale 1ns / 1ps

module uart_sensor_watch (
    input        clk,
    input        rst,
    input        btnR,
    input        btnL,
    input        btnU,
    input        btnD,
    input        echo,      // to sr04 
    input  [2:0] sw,
    input        rx,
    output       tx,
    output       trig,      // from sr04
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [6:0] led,
    inout        dht11
);
    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    // watch, stopwatch data 
    wire [23:0] w_watch_data, w_stopwatch_data, w_fnd_data_in;

    // stopwatch_datapath_control
    wire w_run_stop, w_clear, w_mode; 

    // to control top
    wire w_btnR, w_btnL, w_btnU, w_btnD; 
    wire [4:0] w_ascii_out;  //ascii_s = 5'b00001, ascii_2 = 5'b00010, 
                             //ascii_4 = 5'b00100, ascii_6 = 5'b01000, ascii_8 = 5'b10000;
    // to control watch_datapath
    wire [2:0] w_sel;
    wire w_digit, w_up_down;

    wire [6:0] w_led0;
    wire [1:0] w_led1;

    // to select datapath data    
    wire [1:0] w_datapath_sel;
    wire w_fnd_controller_sel; // select hour/min or sec/msec, sensor only select sec/msec
    
    wire w_sr04_start, w_dht11_start; // to control sensor
    wire [12:0] w_sr04_data, w_dht11_data; // sensor data
    wire [31:0] w_status_data; // to print status data

    // which one should be selected for ascii_s
    wire w_sel_watch_status, w_sel_sw_status, w_sel_sr04_status, w_sel_dht_status;

    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );

    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );

    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );

    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );


    uart_fifo_rx U_UART_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),  //from PC
        .ascii_out(w_ascii_out)
    );

    uart_fifo_tx U_UART_FIFO_TX (
        .clk             (clk),
        .rst             (rst),
        .display_data    (w_status_data),
        .sel_watch_status(w_sel_watch_status),
        .sel_sw_status   (w_sel_sw_status),
        .sel_sr04_status (w_sel_sr04_status),
        .sel_dht_status  (w_sel_dht_status),
        .tx              (tx)                   //To PC
    );

    control_unit U_CNTL_UNIT (
        .clk(clk),
        .rst(rst),
        .btnL(w_btnL),
        .btnD(w_btnD),
        .btnU(w_btnU),
        .btnR(w_btnR),
        .ascii_4(w_ascii_out[2]),  // btnL
        .ascii_2(w_ascii_out[1]),  // btnD
        .ascii_8(w_ascii_out[4]),  // btnU
        .ascii_6(w_ascii_out[3]),  // btnR
        .sw0(sw[0]),  // stopwatch <-> watch, SR04 <-> DHT11
        .sw1(sw[1]),  // Hour/Min <-> sec/msec
        .sw2(sw[2]),  // watch Set Mode <-> IDLE RUN
        .ascii_s(w_ascii_out[0]),  // current status
        .o_sel(w_sel),  // watch, sel hour or min or sec 3'b100
        .o_digit(w_digit),  // watch, sel 1digit or 10digit 1'b
        .o_up_down(w_up_down),  // watch, 0 : up, 1 : down
        .o_mode(w_mode),  // stopwatch,  change up_mode or down_mode
        .o_run_stop(w_run_stop),  // stopwatch, run or stop
        .o_clear(w_clear),  // stopwatch, clear
        .sr04_start(w_sr04_start),  // start sr04 for checking distance
        .dht11_start(w_dht11_start),  // start dht11 for checking Temperature and Humidity
        .datapath_sel(w_datapath_sel),  // select datapath
        .fnd_controller_sel(w_fnd_controller_sel),  // select fnd hour,min or sec,msec
        .sel_watch_status(w_sel_watch_status),  // start ascii_sender about watch_status
        .sel_sw_status(w_sel_sw_status),  // start ascii_sender about stopwatch_status
        .sel_sr04_status(w_sel_sr04_status),  // start ascii_sender about sr04_status
        .sel_dht11_status(w_sel_dht_status),  // start ascii_sender about dht11_status 
        .led0(w_led0),
        .led1(w_led1)
    );


    watch_datapath U_WATCH_DATAPATH (
        .clk      (clk),
        .rst      (rst),
        .i_digit  (w_digit),
        .i_up_down(w_up_down),
        .i_sel    (w_sel),
        .data     (w_watch_data)  // 24 bit 
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_run_stop(w_run_stop),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .data      (w_stopwatch_data)
    );

    sr04_datapath U_SR04_DATAPATH (
        .clk(clk),
        .rst(rst),
        .sr04_start(w_sr04_start),
        .echo(echo),
        .trig(trig),
        .data(w_sr04_data)  //13 bit
    );

    dht11_datapath U_DHT11_DATAPATH (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(w_dht11_start),
        .data       (w_dht11_data),   // [12:7] : temperature, [6:0] humidity
        .dht11      (dht11)
    );

    mux_2x_1_top #(
        .WIDTH(7)
    ) U_LED_SEL (
        .in0    (w_led0),
        .in1    ({5'b00000, w_led1}),
        .mux_sel(w_datapath_sel[0]),
        .out_mux(led)
    );

    mux_4x_1_top #(
        .WIDTH(24)
    ) U_DATAPATH_SEL (
        .in0(w_watch_data),
        .in1(w_stopwatch_data),
        .in2({11'd0, w_sr04_data}),  // 11bit + 13bit
        .in3({11'd0, w_dht11_data}),
        .mux_sel(w_datapath_sel),
        .out_mux(w_fnd_data_in)
    );

    fnd_controller_new U_FND_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sw         (w_fnd_controller_sel),
        .i_digit_led(led[6:3]),
        .time_data  (w_fnd_data_in),
        .fnd_com    (fnd_com),
        .fnd_data   (fnd_data),
        .status_data(w_status_data)
    );

endmodule

module mux_2x_1_top #(
    parameter WIDTH = 7
) (
    input  [WIDTH - 1:0] in0,
    input  [WIDTH - 1:0] in1,
    input                mux_sel,
    output [WIDTH - 1:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;

endmodule

module mux_4x_1_top #(
    parameter WIDTH = 7
) (
    input      [WIDTH - 1:0] in0,
    input      [WIDTH - 1:0] in1,
    input      [WIDTH - 1:0] in2,
    input      [WIDTH - 1:0] in3,
    input      [        1:0] mux_sel,
    output reg [WIDTH - 1:0] out_mux
);

    always @(*) begin
        case (mux_sel)
            2'b00: out_mux = in0;
            2'b01: out_mux = in1;
            2'b10: out_mux = in2;
            2'b11: out_mux = in3;
        endcase
    end

endmodule
