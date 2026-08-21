`timescale 1ns / 1ps

module dht11(
    input           clk,
    input           rst,
    input           btn_R,
    output [3:0]    fnd_com,
    output [7:0]    fnd_data,
    inout           dht11
    );


    wire w_tick_us;
    wire [7:0] w_humidity;
    wire [7:0] w_temperature;
    wire w_valid;

    tick_gen_us U_TICK_GEN_US (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );
    
    // edge detector 

    reg btn_R_d1, btn_R_d2;
    always @(posedge clk) begin
        if (rst) begin
            btn_R_d1 <= 0;
            btn_R_d2 <= 0;
        end else begin
            btn_R_d1 <= btn_R;
            btn_R_d2 <= btn_R_d1;
        end
    end
    wire dht11_start_pulse = btn_R_d1 & ~btn_R_d2;

    dht11_controller U_DHT11_CTRL (
        .clk(clk),
        .rst(rst),
        .dht11_start(dht11_start_pulse), 
        .tick_us(w_tick_us),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .valid(w_valid),
        .dht11(dht11)
    );

    fnd_controller U_FND_CTRL (
        .clk(clk),
        .rst(rst),
        .sw(1'b1),              
        .i_digit_led(4'b1111), 
        .msec({0, w_temperature[6:0]}), 
        .sec({0, w_humidity[5:0]}),     
        .min(6'd0), 
        .hour(5'd0),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


endmodule

module dht11_controller (
    input               clk,
    input               rst,
    input               dht11_start,
    input               tick_us,
    output [7:0]        humidity,
    output [7:0]        temperature,
    output              valid, // for check sum 
    inout               dht11 
);



    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL=3, SYNCH=4;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8, WAIT_HIGH = 9;


    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;                    //recieve bit counter 
    reg [$clog2(19_000)-1:0] tick_cnt_reg, tick_cnt_next;   //general tick count
    reg out_sel_reg, out_sel_next;                          // dht11 io 3state control
    reg dht11_reg, dht11_next;                              //dht11 output drive

    reg [39:0] data_reg, data_next;
    reg dht11_d1, dht11_d2;
    wire dht11_in = dht11_d2;


    // dht11 output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];


    //checksum 
    assign valid = (data_reg[7:0] == (data_reg[39:32]+data_reg[31:24]+data_reg[23:16]+data_reg[15:8])) ? 1'b1 : 1'b0;


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            c_state         <= IDLE;
            bit_cnt_reg     <= 0;
            tick_cnt_reg    <= 0;
            out_sel_reg     <= 1'b1;     // when Idle dht11 output mode
            dht11_reg       <= 1'b1;     // default high state (Idle state)
            data_reg        <= 0;
            dht11_d1 <= 1'b1;
            dht11_d2 <= 1'b1;
        end else begin
            c_state         <= n_state;
            bit_cnt_reg     <= bit_cnt_next;
            tick_cnt_reg    <= tick_cnt_next;
            out_sel_reg     <= out_sel_next;
            dht11_reg       <= dht11_next;
            data_reg        <= data_next;
            dht11_d1 <= dht11;
            dht11_d2 <= dht11_d1;
        end
    end


    always @(*) begin
        n_state         = c_state;
        bit_cnt_next    = bit_cnt_reg;
        tick_cnt_next   = tick_cnt_reg;
        out_sel_next    = out_sel_reg;
        dht11_next      = dht11_reg;
        data_next       = data_reg;

        case (c_state) 
            IDLE : begin
                dht11_next = 1'b1;
                out_sel_next = 1'b1; 
                if (dht11_start) begin
                    bit_cnt_next    = 0;
                    tick_cnt_next   = 0;
                    n_state = START;
                end
            end
            
            START : begin
                dht11_next = 1'b0;
                out_sel_next = 1'b1; 
                if(tick_us) begin
                    if(tick_cnt_reg >= 18_000) begin
                        tick_cnt_next = 0;
                        n_state = WAIT_HIGH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT_HIGH : begin
                out_sel_next = 1'b0; 
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end 
                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = WAIT;
                end else if (tick_cnt_reg > 200) begin 
                    n_state = IDLE;
                end
            end

            WAIT : begin
                out_sel_next = 1'b0; 
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end 
                if (!dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = SYNCL;
                end else if (tick_cnt_reg > 200) begin 
                    n_state = IDLE;
                end
            end
            
            SYNCL : begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;
                
                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = SYNCH;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            SYNCH : begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;
                
                if (!dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            DATA_SYNC : begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;
                
                if (dht11_in) begin
                    tick_cnt_next = 0;
                    n_state = DATA_COUNT;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end

            DATA_COUNT : begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;
                

                if (!dht11_in) begin
                    n_state = DATA_DECISION;
                end else if (tick_cnt_reg > 300) begin
                    n_state = IDLE;
                end
            end

            DATA_DECISION : begin
                out_sel_next = 1'b0;
                
                data_next = {data_reg[38:0], (tick_cnt_reg > 40) ? 1'b1 : 1'b0};
                bit_cnt_next = bit_cnt_reg + 1;
                
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                end else begin
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end
            end

            STOP : begin
                out_sel_next = 1'b0;
                if (tick_us) tick_cnt_next = tick_cnt_reg + 1;
                
                if (dht11_in) begin
                    n_state = IDLE;
                end else if (tick_cnt_reg > 200) begin
                    n_state = IDLE;
                end
            end
            
            default : n_state = IDLE;
        endcase
    end

endmodule

module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);
    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT)-1 : 0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end
endmodule
