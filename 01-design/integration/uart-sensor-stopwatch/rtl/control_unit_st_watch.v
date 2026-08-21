`timescale 1ns / 1ps

module control_unit_st_watch (
    input            clk,
    input            rst,
    input            i_mode,      //down
    input            i_clear,     //left
    input            i_run_stop,  // right
    input            i_btnu,      // undefined
    input      [1:0] sw,
    output           o_mode,
    output reg       o_run_stop,
    output reg       o_clear,
    output     [1:0] o_led
);

    parameter [1:0] STATE_STP = 2'b00;
    parameter [1:0] STATE_RUN = 2'b01;
    parameter [1:0] STATE_CLR = 2'b10;
    parameter [1:0] STATE_MOD = 2'b11;
    //parameter [1:0] STATE_STP = 0, STATE_RUN = 1, STATE_CLR = 2, STATE_MOD = 3;

    reg [1:0] current_state, next_state;
    reg mode_reg, mode_next;

    assign o_mode = mode_reg;

    assign o_led  = sw;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STATE_STP;
            mode_reg      <= 1'b0;
        end else begin
            current_state <= next_state;
            mode_reg      <= mode_next;
        end
    end

    // next, output CL

    always @(*) begin
        next_state = current_state;
        mode_next = mode_reg;
        o_clear = 1'b0;
        o_run_stop = 1'b0;

        case (current_state)
            STATE_STP: begin
                o_run_stop = 1'b0;
                o_clear    = 1'b0;
                if (i_run_stop) next_state = STATE_RUN;
                else if (i_clear) next_state = STATE_CLR;
                else if (i_mode) next_state = STATE_MOD;
                else next_state = current_state;
            end
            STATE_RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) next_state = STATE_STP;
                //else             next_state = current_state;
            end
            STATE_CLR: begin
                o_clear    = 1'b1;
                next_state = STATE_STP;
            end
            STATE_MOD: begin
                next_state = STATE_STP;
                mode_next  = ~mode_reg;
            end
        endcase
    end
    
endmodule
