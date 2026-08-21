`timescale 1ns / 1ps

module control_unit_watch (
    input            clk,
    input            rst,
    input            btnL,
    input            btnR,
    input            btnU,
    input            btnD,
    input            sw_display,  //sw[1]
    input            sw_btn,      // sw[2]
    output reg [6:0] o_led,
    output reg [2:0] o_sel,
    output reg       o_digit,
    output reg       o_up_down
);

    parameter RUN_HOUR_MIN = 0;
    parameter RUN_SEC_MSEC = 1;
    parameter SET_10_HOUR = 2;
    parameter CH_10U_HOUR = 3;
    parameter CH_10D_HOUR = 4;
    parameter SET_1_HOUR = 5;
    parameter CH_1U_HOUR = 6;
    parameter CH_1D_HOUR = 7;
    parameter SET_10_MIN = 8;
    parameter CH_10U_MIN = 9;
    parameter CH_10D_MIN = 10;
    parameter SET_1_MIN = 11;
    parameter CH_1U_MIN = 12;
    parameter CH_1D_MIN = 13;
    parameter SET_10_SEC = 14;
    parameter CH_10U_SEC = 15;
    parameter CH_10D_SEC = 16;
    parameter SET_1_SEC = 17;
    parameter CH_1U_SEC = 18;
    parameter CH_1D_SEC = 19;

    reg [4:0] current_state, next_state;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= RUN_HOUR_MIN;
        end else current_state <= next_state;
    end

    // next state
    always @(*) begin
        o_led[6:0] = 7'b0000000;
        o_sel = 3'b000;  //3'b001 : sec, 3'b010 : min, 3'b100 : hour
        o_digit = 1'b0;  // 1'b1 : digit1, 1'b0 : digit10
        o_up_down = 1'b0;  // 1'b0 : up, 1'b1 : down
        next_state = current_state;
        case (current_state)
            RUN_HOUR_MIN: begin
                o_led = 7'b0000000;
                if (sw_display) next_state = RUN_SEC_MSEC;
                else if (btnR & sw_btn) next_state = SET_10_HOUR;
                else if (btnL & sw_btn) next_state = SET_1_MIN;
            end
            RUN_SEC_MSEC: begin
                o_led = 7'b0000010;
                if (!sw_display) next_state = RUN_HOUR_MIN;
                else if (btnR & sw_btn) next_state = SET_10_SEC;
                else if (btnL & sw_btn) next_state = SET_1_SEC;
            end
            SET_10_HOUR: begin
                o_led = 7'b1000100;
                if (!sw_btn) next_state = RUN_HOUR_MIN;
                else if (btnL) next_state = SET_1_MIN;
                else if (btnR) next_state = SET_1_HOUR;
                else if (btnU) next_state = CH_10U_HOUR;
                else if (btnD) next_state = CH_10D_HOUR;
                else if (sw_display) next_state = SET_10_SEC;
            end
            CH_10U_HOUR: begin
                o_sel = 3'b100;
                o_digit = 1'b0;
                o_up_down = 1'b0;
                next_state = SET_10_HOUR;
            end
            CH_10D_HOUR: begin
                o_sel = 3'b100;
                o_digit = 1'b0;
                o_up_down = 1'b1;
                next_state = SET_10_HOUR;
            end
            SET_1_HOUR: begin
                o_led = 7'b0100100;
                if (!sw_btn) next_state = RUN_HOUR_MIN;
                else if (btnL) next_state = SET_10_HOUR;
                else if (btnR) next_state = SET_10_MIN;
                else if (btnU) next_state = CH_1U_HOUR;
                else if (btnD) next_state = CH_1D_HOUR;
                else if (sw_display) next_state = SET_1_SEC;
            end
            CH_1U_HOUR: begin
                o_sel = 3'b100;
                o_digit = 1'b1;
                o_up_down = 1'b0;
                next_state = SET_1_HOUR;
            end
            CH_1D_HOUR: begin
                o_sel = 3'b100;
                o_digit = 1'b1;
                o_up_down = 1'b1;
                next_state = SET_1_HOUR;
            end
            SET_10_MIN: begin
                o_led = 7'b0010100;
                if (!sw_btn) next_state = RUN_HOUR_MIN;
                else if (btnL) next_state = SET_1_HOUR;
                else if (btnR) next_state = SET_1_MIN;
                else if (btnU) next_state = CH_10U_MIN;
                else if (btnD) next_state = CH_10D_MIN;
                else if (sw_display) next_state = SET_10_SEC;
            end
            CH_10U_MIN: begin
                o_sel = 3'b010;
                o_digit = 1'b0;
                o_up_down = 1'b0;
                next_state = SET_10_MIN;
            end
            CH_10D_MIN: begin
                o_sel = 3'b010;
                o_digit = 1'b0;
                o_up_down = 1'b1;
                next_state = SET_10_MIN;
            end
            SET_1_MIN: begin
                o_led = 7'b0001100;
                if (!sw_btn) next_state = RUN_HOUR_MIN;
                else if (btnL) next_state = SET_10_MIN;
                else if (btnR) next_state = SET_10_HOUR;
                else if (btnU) next_state = CH_1U_MIN;
                else if (btnD) next_state = CH_1D_MIN;
                else if (sw_display) next_state = SET_1_SEC;
            end
            CH_1U_MIN: begin
                o_sel = 3'b010;
                o_digit = 1'b1;
                o_up_down = 1'b0;
                next_state = SET_1_MIN;
            end
            CH_1D_MIN: begin
                o_sel = 3'b010;
                o_digit = 1'b1;
                o_up_down = 1'b1;
                next_state = SET_1_MIN;
            end
            SET_10_SEC: begin
                o_led = 7'b1000110;
                if (!sw_btn) next_state = RUN_SEC_MSEC;
                else if (btnL) next_state = SET_1_SEC;
                else if (btnR) next_state = SET_1_SEC;
                else if (btnU) next_state = CH_10U_SEC;
                else if (btnD) next_state = CH_10D_SEC;
                else if (!sw_display) next_state = SET_10_HOUR;
            end
            CH_10U_SEC: begin
                o_sel = 3'b001;
                o_digit = 1'b0;
                o_up_down = 1'b0;
                next_state = SET_10_SEC;
            end
            CH_10D_SEC: begin
                o_sel = 3'b001;
                o_digit = 1'b0;
                o_up_down = 1'b1;
                next_state = SET_10_SEC;
            end
            SET_1_SEC: begin
                o_led = 7'b0100110;
                if (!sw_btn) next_state = RUN_SEC_MSEC;
                else if (btnL) next_state = SET_10_SEC;
                else if (btnR) next_state = SET_10_SEC;
                else if (btnU) next_state = CH_1U_SEC;
                else if (btnD) next_state = CH_1D_SEC;
                else if (!sw_display) next_state = SET_1_HOUR;
            end
            CH_1U_SEC: begin
                o_sel = 3'b001;
                o_digit = 1'b1;
                o_up_down = 1'b0;
                next_state = SET_1_SEC;
            end
            CH_1D_SEC: begin
                o_sel = 3'b001;
                o_digit = 1'b1;
                o_up_down = 1'b1;
                next_state = SET_1_SEC;
            end
        endcase

        if (sw_btn) o_led[2] = 1'b1;
    end

endmodule
