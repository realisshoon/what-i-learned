`timescale 1ns / 1ps

module input_controller (
    input clk, 
    input rst,
    input sw2_enable,      // sw[2] (라우터 제어용)

    input btnR, btnL, btnD, btnU, 
    
    output wt_btnR, wt_btnL, wt_btnD, wt_btnU,
    
    output sw_btnR, sw_btnL, sw_btnD, sw_btnU
);

    // --------------------------------------------------
    // 1. 내부 와이어 선언 (디바운서 -> 라우터 연결용 선)
    // --------------------------------------------------
    wire db_btnR, db_btnL, db_btnD, db_btnU;

    // --------------------------------------------------
    // 2. 디바운스 부품 4개 조립
    // --------------------------------------------------
    button_debounce U_DB_R (.clk(clk), .rst(rst), .i_btn(btnR), .o_btn(db_btnR));
    button_debounce U_DB_L (.clk(clk), .rst(rst), .i_btn(btnL), .o_btn(db_btnL));
    button_debounce U_DB_D (.clk(clk), .rst(rst), .i_btn(btnD), .o_btn(db_btnD));
    button_debounce U_DB_U (.clk(clk), .rst(rst), .i_btn(btnU), .o_btn(db_btnU));

    // --------------------------------------------------
    // 3. 디멀티플렉서
    // 디바운스된 신호(db_btn)를 받아서 모드(sw2)에 따라 양쪽으로 분배
    // --------------------------------------------------
    button_router U_ROUTER (
        .mode        (sw2_enable), 
        
        // 입력: 디바운스된 신호
        .in_btnR     (db_btnR), 
        .in_btnL     (db_btnL),
        .in_btnD     (db_btnD),
        .in_btnU     (db_btnU),
        
        // 출력 1: 스톱워치로 갈 선
        .out_sw_btnR (sw_btnR), 
        .out_sw_btnL (sw_btnL),
        .out_sw_btnD (sw_btnD),
        .out_sw_btnU (sw_btnU),

        // 출력 2: 시계로 갈 선
        .out_wt_btnR (wt_btnR),
        .out_wt_btnL (wt_btnL),
        .out_wt_btnD (wt_btnD),
        .out_wt_btnU (wt_btnU)
    );

endmodule


module button_router (
    input mode, // sw[2] (0: Watch 모드, 1: Stopwatch 모드)
    
    // 디바운스를 통과한 원본 버튼 입력
    input in_btnR,
    input in_btnL,
    input in_btnD,
    input in_btnU,
    
    // 스톱워치 제어부로 나갈 출력
    output out_sw_btnR,
    output out_sw_btnL,
    output out_sw_btnD,
    output out_sw_btnU,

    // 시계 제어부로 나갈 출력
    output out_wt_btnR,
    output out_wt_btnL,
    output out_wt_btnD,
    output out_wt_btnU
);

    // mode가 1일 때(Stopwatch) 스톱워치로 전달, 0일 땐 차단
    assign out_sw_btnR = (mode) ? in_btnR : 1'b0;
    assign out_sw_btnL = (mode) ? in_btnL : 1'b0;
    assign out_sw_btnD = (mode) ? in_btnD : 1'b0;
    assign out_sw_btnU = (mode) ? in_btnU : 1'b0;

    // mode가 0일 때(Watch) 시계로 전달, 1일 땐 차단
    assign out_wt_btnR = (~mode) ? in_btnR : 1'b0;
    assign out_wt_btnL = (~mode) ? in_btnL : 1'b0;
    assign out_wt_btnD = (~mode) ? in_btnD : 1'b0;
    assign out_wt_btnU = (~mode) ? in_btnU : 1'b0;

endmodule

module button_debounce(
    input       clk,
    input       rst,
    input       i_btn,
    output      o_btn
    );

    // clock diver
    // 100Mhz -> 100Khz
    // parameter F_COUNT = 100_000_000 / 100_000;
    parameter F_COUNT = 5;
    reg [$clog2(F_COUNT)-1 : 0] r_counter;
    reg clk_100khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            clk_100khz <= 1'b0;
        end else begin
            r_counter <= r_counter + 1'b1;
            if (r_counter == F_COUNT - 1) begin
                r_counter <= 0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end

    // syncronizer
    reg [7:0] sync_reg, sync_next;
    wire debounce;
    reg edge_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            sync_reg <= 0;
        end else if (clk_100khz) begin
            sync_reg <= sync_next;
        end
    end

    always @(*) begin
        sync_next = {i_btn,sync_reg[7:1]};
    end

    assign debounce = &sync_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce &(~edge_reg);

endmodule