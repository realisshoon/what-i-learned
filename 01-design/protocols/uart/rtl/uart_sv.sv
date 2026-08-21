`timescale 1ns / 1ps

module uart_sv(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic       tx,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_err_frame
);

    logic w_tick;

    baud_tick_gen U_BAUD_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    uart_tx_sv U_UART_TX(
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .b_tick(w_tick),
        .tx_busy(tx_busy),
        .tx(tx)
    );

    // UART Receiver
    uart_rx_sv U_UART_RX(
        .clk(clk),
        .rst(rst),
        .b_tick(w_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_err_frame(rx_err_frame)
    );

endmodule




module uart_tx_sv(
    input  logic       clk,
    input  logic       rst,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    input  logic       b_tick,
    output logic       tx_busy,
    output logic       tx
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state;

    logic [7:0] data_reg, data_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [3:0] s_cnt_reg, s_cnt_next; // 16x tick counter
    logic       tx_reg, tx_next;

    assign tx = tx_reg;
    assign tx_busy = (state != IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            data_reg    <= 8'b0;
            bit_cnt_reg <= 3'b0;
            s_cnt_reg   <= 4'b0;
            tx_reg      <= 1'b1;
        end else begin
            state       <= next_state;
            data_reg    <= data_next;
            bit_cnt_reg <= bit_cnt_next;
            s_cnt_reg   <= s_cnt_next;
            tx_reg      <= tx_next;
        end
    end

    always_comb begin
        next_state   = state;
        data_next    = data_reg;
        bit_cnt_next = bit_cnt_reg;
        s_cnt_next   = s_cnt_reg;
        tx_next      = tx_reg;

        case (state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    data_next  = tx_data;
                    s_cnt_next = 4'd0;
                    next_state = START;
                end
            end
            START: begin
                tx_next = 1'b0; // START bit
                if (b_tick) begin
                    if (s_cnt_reg == 4'd15) begin
                        s_cnt_next   = 4'd0;
                        bit_cnt_next = 3'd0;
                        next_state   = DATA;
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
            DATA: begin
                tx_next = data_reg[0]; // LSB first
                if (b_tick) begin
                    if (s_cnt_reg == 4'd15) begin
                        s_cnt_next = 4'd0;
                        data_next  = {1'b0, data_reg[7:1]};
                        if (bit_cnt_reg == 3'd7) begin
                            next_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1; // STOP bit
                if (b_tick) begin
                    if (s_cnt_reg == 4'd15) begin
                        next_state = IDLE;
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
        endcase
    end
endmodule


module uart_rx_sv(
    input  logic       clk,
    input  logic       rst,
    input  logic       b_tick,
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_err_frame
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state;

    logic [7:0] data_reg, data_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [3:0] s_cnt_reg, s_cnt_next; // 16x tick counter

    // RX input synchronizer & Edge Detector
    logic rx_sync1, rx_sync2, rx_sync3;
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
            rx_sync3 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            rx_sync3 <= rx_sync2;
        end
    end

    logic rx_falling_edge;
    assign rx_falling_edge = (rx_sync3 == 1'b1 && rx_sync2 == 1'b0);

    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            data_reg    <= 8'b0;
            bit_cnt_reg <= 3'b0;
            s_cnt_reg   <= 4'b0;
        end else begin
            state       <= next_state;
            data_reg    <= data_next;
            bit_cnt_reg <= bit_cnt_next;
            s_cnt_reg   <= s_cnt_next;
        end
    end

    assign rx_data = data_reg;

    always_comb begin
        next_state   = state;
        data_next    = data_reg;
        bit_cnt_next = bit_cnt_reg;
        s_cnt_next   = s_cnt_reg;
        rx_done      = 1'b0;
        rx_err_frame = 1'b0;

        case (state)
            IDLE: begin
                if (rx_falling_edge) begin
                    s_cnt_next = 4'd0;
                    next_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    // 7th tick is the center of the START bit
                    if (s_cnt_reg == 4'd7) begin
                        s_cnt_next   = 4'd0;
                        bit_cnt_next = 3'd0;
                        next_state   = DATA;
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    // Wait 16 ticks to get to the center of the next bit
                    if (s_cnt_reg == 4'd15) begin
                        s_cnt_next = 4'd0;
                        data_next  = {rx_sync2, data_reg[7:1]};
                        
                        if (bit_cnt_reg == 3'd7) begin
                            next_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    // Wait 16 ticks for the center of the STOP bit
                    if (s_cnt_reg == 4'd15) begin
                        if (rx_sync2 == 1'b0) rx_err_frame = 1'b1;
                        else begin
                            rx_done    = 1'b1;
                        end
                        next_state = IDLE;
                    end else begin
                        s_cnt_next = s_cnt_reg + 1'b1;
                    end
                end
            end
        endcase
    end
endmodule

module baud_tick_gen(
    input  logic clk,
    input  logic rst,
    output logic o_tick
);
    localparam   MAX_TICK_CNT = 54;
    logic [9:0] tick_counter;

    always_ff @(posedge clk) begin
        if (rst) begin
            tick_counter <= 0;
            o_tick       <= 0;
        end else if (tick_counter == MAX_TICK_CNT-1) begin
            tick_counter <= 0;
            o_tick       <= 1;
        end else begin
            tick_counter <= tick_counter + 1;
            o_tick       <= 0;
        end
    end
endmodule