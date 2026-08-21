`timescale 1ns / 1ps

module watch_control_unit (
    input clk,
    input rst,
    input sw,       
    input i_btnL,    
    input i_btnR,   
    
    output [1:0] o_state
);

    // 상태 정의
    parameter [1:0] NORMAL = 2'b00, SET_SEC = 2'b01, SET_MIN = 2'b10, SET_HOUR = 2'b11;
    reg [1:0] c_state, n_state;

    // Sequential Logic 
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= NORMAL;
        end else begin

            if (sw) c_state <= NORMAL; 
            else    c_state <= n_state;
        end
    end

    // Combinational Logic 
    always @(*) begin
        n_state = c_state; 

        case (c_state)
            NORMAL: begin
                if (i_btnL)      n_state = SET_SEC;  
                else if (i_btnR) n_state = SET_HOUR; 
            end
            
            SET_SEC: begin
                if (i_btnL)      n_state = SET_MIN;  
                else if (i_btnR) n_state = NORMAL;   
            end
            
            SET_MIN: begin
                if (i_btnL)      n_state = SET_HOUR; 
                else if (i_btnR) n_state = SET_SEC;  
            end
            
            SET_HOUR: begin
                if (i_btnL)      n_state = NORMAL;  
                else if (i_btnR) n_state = SET_MIN; 
            end
            
            default: n_state = NORMAL;
        endcase
    end

    assign o_state = c_state;

endmodule