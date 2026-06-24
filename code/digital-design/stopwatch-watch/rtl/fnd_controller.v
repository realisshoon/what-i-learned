`timescale 1ns / 1ps

module fnd_controller #(
    localparam MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input       clk,
    input       rst,
    input [1:0] sw,
    input [1:0] i_state,

    // Top 모듈에서 스톱워치/시계 데이터를 모두 받을 수 있게 포트 확장
    input [MSEC_WIDTH-1:0] sw_msec,
    input [ SEC_WIDTH-1:0] sw_sec,
    input [ MIN_WIDTH-1:0] sw_min,
    input [HOUR_WIDTH-1:0] sw_hour,

    input [MSEC_WIDTH-1:0] wt_msec,
    input [ SEC_WIDTH-1:0] wt_sec,
    input [ MIN_WIDTH-1:0] wt_min,
    input [HOUR_WIDTH-1:0] wt_hour,

    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire [MSEC_WIDTH-1:0] mux_msec;
    wire [ SEC_WIDTH-1:0] mux_sec;
    wire [ MIN_WIDTH-1:0] mux_min;
    wire [HOUR_WIDTH-1:0] mux_hour;

    wire [3:0] w_out_mux, w_out_mux_msec_sec, w_out_mux_min_hour;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [2:0] w_digit_sel;
    wire       w_1khz;
    wire       w_dot_onoff;
    wire [7:0] w_bcd_data;
    wire [3:0] w_dot_1, w_dot_10, w_dot_100, w_dot_1000;
    wire [6:0] w_ui_msec;

    assign fnd_data = w_bcd_data;

    // 데이터 선택 (스톱워치 vs 시계)
    display_mux U_DISPLAY_MUX (
        .sel(sw[0]),
        .sw_msec(sw_msec),
        .sw_sec(sw_sec),
        .sw_min(sw_min),
        .sw_hour(sw_hour),
        .wt_msec(wt_msec),
        .wt_sec(wt_sec),
        .wt_min(wt_min),
        .wt_hour(wt_hour),
        .out_msec(mux_msec),
        .out_sec(mux_sec),
        .out_min(mux_min),
        .out_hour(mux_hour)
    );

    // 도트 점등 위치 제어
    dot_mapper U_DOT_MAPPER (
        .i_disp_mode(sw[0]),
        .i_res_mode(sw[1]),
        .i_state(i_state),
        .i_blink(w_dot_onoff),
        .o_dot_1(w_dot_1),
        .o_dot_10(w_dot_10),
        .o_dot_100(w_dot_100),
        .o_dot_1000(w_dot_1000)
    );


    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(mux_msec),  // msec -> mux_msec 로 변경
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(mux_sec),  // sec -> mux_sec 로 변경
        .digit_1(w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(mux_min),  // min -> mux_min 로 변경
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(mux_hour),  // hour -> mux_hour 로 변경
        .digit_1(w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );


    ui_msec_counter U_UI_MSEC_CNT (
        .clk   (w_1khz),
        .rst   (rst),
        .o_msec(w_ui_msec)
    );

    comparator_7bit U_COMP_MSEC (
        .comp_in  (w_ui_msec),  
        .dot_onoff(w_dot_onoff)
    );

    mux_8x1 U_MUX_MSEC_SEC (
        .in0    (w_msec_digit_1),
        .in1    (w_msec_digit_10),
        .in2    (w_sec_digit_1),
        .in3    (w_sec_digit_10),
        .in4    (4'hF),
        .in5    (4'hF),
        .in6    (w_dot_100),         
        .in7    (w_dot_1000),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_msec_sec)
    );
    mux_8x1 U_MUX_MIN_HOUR (
        .in0    (w_min_digit_1),
        .in1    (w_min_digit_10),
        .in2    (w_hour_digit_1),
        .in3    (w_hour_digit_10),
        .in4    (w_dot_1),           
        .in5    (w_dot_10),          
        .in6    (w_dot_100),          
        .in7    (w_dot_1000),        
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_min_hour)
    );

    mux_2x1 U_MUX_2x1 (
        .in0    (w_out_mux_msec_sec),
        .in1    (w_out_mux_min_hour),
        .sel    (sw[1]),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin(w_out_mux),
        .bcd_data(w_bcd_data)
    );


    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .decoder_in(w_digit_sel[1:0]),
        .fnd_com   (fnd_com)
    );

endmodule


module display_mux #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input sel,  // sw[0] (1: 스톱워치, 0: 시계)

    // 스톱워치 데이터 입력 (sel == 1)
    input [MSEC_WIDTH-1:0] sw_msec,
    input [ SEC_WIDTH-1:0] sw_sec,
    input [ MIN_WIDTH-1:0] sw_min,
    input [HOUR_WIDTH-1:0] sw_hour,

    // 시계 데이터 입력 (sel == 0)
    input [MSEC_WIDTH-1:0] wt_msec,
    input [ SEC_WIDTH-1:0] wt_sec,
    input [ MIN_WIDTH-1:0] wt_min,
    input [HOUR_WIDTH-1:0] wt_hour,

    // 최종 FND로 나갈 출력
    output [MSEC_WIDTH-1:0] out_msec,
    output [ SEC_WIDTH-1:0] out_sec,
    output [ MIN_WIDTH-1:0] out_min,
    output [HOUR_WIDTH-1:0] out_hour
);

    assign out_msec = (sel) ? sw_msec : wt_msec;
    assign out_sec  = (sel) ? sw_sec : wt_sec;
    assign out_min  = (sel) ? sw_min : wt_min;
    assign out_hour = (sel) ? sw_hour : wt_hour;

endmodule


module ui_msec_counter (
    input        clk,    // 1kHz 클럭 입력
    input        rst,
    output [6:0] o_msec  // 0~99 출력
);
    reg [6:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 7'd0;
        end else begin
            if (counter_reg >= 7'd99) counter_reg <= 7'd0;
            else counter_reg <= counter_reg + 1'b1;
        end
    end

    assign o_msec = counter_reg;

endmodule

module comparator_7bit (
    input  [6:0] comp_in,
    output       dot_onoff
);
    localparam THRESHOLD = 7'd49;
    assign dot_onoff = (comp_in > THRESHOLD) ? 1'b1 : 1'b0;
endmodule



module mux_2x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input        sel,
    output [3:0] out_mux
);
    assign out_mux = sel ? in1 : in0;  // in1 : (min/hour) ,in0 : (msec/sec) 
endmodule


module clk_div_1khz #(
    parameter SCAN_MAX = 50_000
) (
    input clk,
    input rst,
    output reg o_1khz
);
    reg [$clog2(SCAN_MAX)-1:0] counter_reg;  


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_1khz <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == (SCAN_MAX - 1)) begin
                counter_reg <= 0;
                o_1khz <= ~o_1khz;
            end
        end
    end
endmodule

module counter_8 (
    input clk,
    input rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg;
    assign digit_sel = counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 3'b000;
        end else begin
            counter_reg <= counter_reg + 1'b1;
        end
    end
endmodule



module decoder_2x4 (
    input [1:0] decoder_in,
    output reg [3:0] fnd_com
);
    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule


module dot_mapper (
    input i_disp_mode,  // sw[0] (1: 스톱워치 화면, 0: 시계 화면)
    input i_res_mode,  // sw[1] (1: [시:분] 화면, 0: [초:밀리초] 화면)
    input [1:0] i_state,  // 00:NORMAL, 01:SET_SEC, 10:SET_MIN, 11:SET_HOUR
    input i_blink,
    output [3:0] o_dot_1,  // 분/밀리초 1의 자리
    output [3:0] o_dot_10,  // 분/밀리초 10의 자리
    output [3:0] o_dot_100,  // 시/초 1의 자리 (가운데 콜론)
    output [3:0] o_dot_1000  // 시/초 10의 자리
);
    wire [3:0] active_dot = (i_blink) ? 4'hE : 4'hF;
    reg [3:0] d1, d10, d100, d1000;

    always @(*) begin
        // 기본값: 모든 점 소등
        d1 = 4'hF;
        d10 = 4'hF;
        d100 = 4'hF;
        d1000 = 4'hF;

        // 1. 스톱워치 화면 (sw[0] == 1)
        if (i_disp_mode == 1'b1) begin
            d100 = active_dot; // 스톱워치는 무조건 가운데 점만 깜빡임!
        end  // 2. 시계 화면 (sw[0] == 0)
        else begin
            if (i_state == 2'b00) begin
                d100 = active_dot;  // NORMAL: 가운데만 깜빡임
            end else if (i_res_mode == 1'b1) begin
                // [시:분] 화면 (sw[1] == 1)
                if (i_state == 2'b11) begin  // 시 설정 중
                    d1000 = active_dot;
                    d100  = active_dot;
                end else if (i_state == 2'b10) begin  // 분 설정 중
                    d10 = active_dot;
                    d1  = active_dot;
                end else begin
                    d100 = active_dot; // 초를 설정 중인데 화면을 돌리면 가운데만 유지
                end
            end else if (i_res_mode == 1'b0) begin
                //
                if (i_state == 2'b01) begin  // 초 설정 중
                    d1000 = active_dot;
                    d100  = active_dot;
                end else begin
                    d100 = active_dot; // 시/분을 설정 중인데 화면을 돌리면 가운데만 유지
                end
            end
        end
    end

    assign o_dot_1    = d1;
    assign o_dot_10   = d10;
    assign o_dot_100  = d100;
    assign o_dot_1000 = d1000;
endmodule



module mux_8x1 (
    input [3:0] in0,
    in1,
    in2,
    in3,
    input [3:0] in4,
    in5,
    in6,
    in7,
    input [2:0] sel,
    output reg [3:0] out_mux
);
    always @(*) begin
        case (sel)
            3'd0: out_mux = in0;
            3'd1: out_mux = in1;
            3'd2: out_mux = in2;
            3'd3: out_mux = in3;
            3'd4: out_mux = in4;
            3'd5: out_mux = in5;
            3'd6: out_mux = in6;
            3'd7: out_mux = in7;
            default: out_mux = 4'hF;
        endcase
    end
endmodule


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] digit_in,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
endmodule


module bcd (
    input [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;  //0
            4'b0001: bcd_data = 8'hF9;  //1
            4'b0010: bcd_data = 8'hA4;  //2
            4'b0011: bcd_data = 8'hB0;  //3
            4'b0100: bcd_data = 8'h99;  //4
            4'b0101: bcd_data = 8'h92;  //5
            4'b0110: bcd_data = 8'h82;  //6
            4'b0111: bcd_data = 8'hF8;  //7
            4'b1000: bcd_data = 8'h80;  //8
            4'b1001: bcd_data = 8'h90;  //9
            4'b1010: bcd_data = 8'h88;  //a
            4'b1011: bcd_data = 8'h83;  //b
            4'b1100: bcd_data = 8'hC6;  //c
            4'b1101: bcd_data = 8'hA1;  //d
            4'b1110: bcd_data = 8'h7F;  // dot on
            4'b1111: bcd_data = 8'hFF;  // all of
            default: bcd_data = 8'hFF;  // off
        endcase
    end

endmodule
