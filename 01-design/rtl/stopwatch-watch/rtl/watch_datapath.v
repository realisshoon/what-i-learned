`timescale 1ns / 1ps

module watch_datapath #(
    localparam MSEC_WIDTH = 7,
    localparam SEC_WIDTH  = 6,
    localparam MIN_WIDTH  = 6,
    localparam HOUR_WIDTH = 5
) (
    input clk,
    input rst,


    input [1:0] i_state,      
    input       i_btnU_tick,  
    input       i_btnD_tick,  


    output [MSEC_WIDTH-1:0] o_msec,
    output [ SEC_WIDTH-1:0] o_sec,
    output [ MIN_WIDTH-1:0] o_min,
    output [HOUR_WIDTH-1:0] o_hour
);


    wire w_tick_100hz;
    wire w_msec_carry, w_sec_carry, w_min_carry;

    wire w_set_sec = (i_state == 2'b01);
    wire w_set_min = (i_state == 2'b10);
    wire w_set_hour = (i_state == 2'b11);

    tick_gen_100hz U_TICK_GEN_100HZ (
        .clk         (clk),
        .rst         (rst),
        .i_clear     (1'b0),      
        .i_run_stop  (1'b1),       
        .o_tick_100hz(w_tick_100hz)
    );
    watch_counter #(
        .MAX_VAL  (99),
        .INIT_VAL (0),
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_bg_tick(w_tick_100hz),  
        .i_set_mode (i_state != 2'b00),         
        .i_btnU(1'b0),
        .i_btnD(1'b0),
        .o_val(o_msec),
        .o_carry    (w_msec_carry)  
    );

    watch_counter #(
        .MAX_VAL  (59),
        .INIT_VAL (0),
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_bg_tick  (w_msec_carry), 
        .i_set_mode(w_set_sec),  
        .i_btnU(i_btnU_tick),
        .i_btnD(i_btnD_tick),
        .o_val(o_sec),
        .o_carry(w_sec_carry) 
    );


    watch_counter #(
        .MAX_VAL  (59),
        .INIT_VAL (0),
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_COUNTER (
        .clk       (clk),
        .rst       (rst),
        .i_bg_tick (w_sec_carry),  
        .i_set_mode(w_set_min),    
        .i_btnU    (i_btnU_tick),
        .i_btnD    (i_btnD_tick),
        .o_val     (o_min),
        .o_carry   (w_min_carry)   
    );

    // [시] 카운터 (리셋 시 12시로 초기화!)
    watch_counter #(
        .MAX_VAL  (23),
        .INIT_VAL (12),         
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_bg_tick(w_min_carry), 
        .i_set_mode(w_set_hour),  
        .i_btnU(i_btnU_tick),
        .i_btnD(i_btnD_tick),
        .o_val(o_hour),
        .o_carry    ()              // 시의 캐리는 사용하지 않음 (일(Day)이 없으므로)
    );

endmodule


// ==========================================
// 시계 전용 카운터 모듈 
// ==========================================
module watch_counter #(
    parameter MAX_VAL   = 59,
    parameter INIT_VAL  = 0,
    parameter BIT_WIDTH = 6
) (
    input clk,
    input rst,

    input i_bg_tick,
    input i_set_mode,
    input i_btnU,
    input i_btnD,

    output reg [BIT_WIDTH-1:0] o_val,
    output reg                 o_carry
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_val   <= INIT_VAL;
            o_carry <= 1'b0;
        end else begin
            o_carry <= 1'b0;

            // i_set_mode 일 때는 bg_tick을 아예 안 탐! (시간 멈춤)
            if (i_set_mode) begin
                if (i_btnU) begin
                    if (o_val == MAX_VAL) o_val <= 0;
                    else o_val <= o_val + 1'b1;
                end else if (i_btnD) begin
                    if (o_val == 0) o_val <= MAX_VAL;
                    else o_val <= o_val - 1'b1;
                end
            end 
            // 설정 모드가 아닐(NORMAL) 때만 시간이 자연스럽게 흐름!
            else if (i_bg_tick) begin
                if (o_val == MAX_VAL) begin
                    o_val   <= 0;
                    o_carry <= 1'b1;
                end else begin
                    o_val <= o_val + 1'b1;
                end
            end
        end
    end

endmodule


