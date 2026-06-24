`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/14 08:46:02
// Design Name: 
// Module Name: fsm_led
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fsm_led (
    input clk,
    input rst,
    input [2:0] sw,
    output [2:0] led
);

    // state 정의
    localparam [2:0] STATE_A = 3'b000, STATE_B = 3'b001, STATE_C = 3'b010, STATE_D = 3'b011, STATE_E = 3'b100;

    // output SL
    reg [2:0] led_reg, led_next;

    assign led = led_reg;

    // 1. state register 
    reg [2:0] current_state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_A;
            led_reg <= 3'b000;
        end else begin
            current_state <= next_state;
            led_reg <= led_next;
        end
    end

    // 2. next state, output Combinational Logic + SL
    always @(*) begin
        next_state = current_state;
        led_next   = led_reg;
        case (current_state)
            STATE_A: begin
                // led_next = 3'b000;// moore 
                if (sw == 3'b001) begin
                    led_next   = 3'b001;
                    next_state = STATE_B;
                end else if (sw == 3'b010) begin
                    led_next   = 3'b010;
                    next_state = STATE_C;
                end else begin
                    next_state = current_state; // 지정된 입력 외에는 현재 상태 유지\
                end
            end
            STATE_B: begin
                // led_next = 3'b001;// moore 
                if (sw == 3'b010) begin
                    led_next   = 3'b010;
                    next_state = STATE_C;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_C: begin
                // led_next = 3'b010;// moore 
                if (sw == 3'b100) begin
                    led_next   = 3'b100;
                    next_state = STATE_D;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_D: begin
                // led_next = 3'b100;  // moore 
                if (sw == 3'b000) begin
                    led_next   = 3'b000;
                    next_state = STATE_A;
                end else if (sw == 3'b001) begin
                    led_next   = 3'b001;
                    next_state = STATE_B;
                end else if (sw == 3'b111) begin
                    led_next   = 3'b111;
                    next_state = STATE_E;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_E: begin
                // led_next = 3'b111; // moore 
                if (sw == 3'b000) begin
                    led_next   = 3'b000;
                    next_state = STATE_A;
                end else begin
                    next_state = current_state;
                end
            end
            // default:
            //     next_state = current_state;
        endcase
    end

    // 3. output Combinational Logic
    // always @(*) begin
    //     case(current_state)
    //         STATE_A : led = 3'b000;
    //         STATE_B : led = 3'b001;
    //         STATE_C : led = 3'b010;
    //         STATE_D : led = 3'b100;
    //         STATE_E : led = 3'b111;
    //         default : led = 3'b000;
    //     endcase
    // end




endmodule

