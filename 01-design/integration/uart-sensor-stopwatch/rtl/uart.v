`timescale 1ns / 1ps

module uart (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       tx_busy,
    output       tx
);

    wire w_b_tick;


    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),
        .tx_data (tx_data),   // 8'h30 ascii 0 
        .b_tick  (w_b_tick),
        .tx_busy (tx_busy),
        .tx      (tx)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule

module uart_rx_top (
    input        clk,
    input        rst,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    wire w_b_tick;

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


endmodule

module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg, data_next;
    reg rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            data_reg <= 0;
            rx_done_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            data_reg <= data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    //next, output 
    always @(*) begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        data_next = data_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 0;
                if (b_tick && (!rx)) begin
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        bit_cnt_next    = 0;
                        b_tick_cnt_next = 0;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        data_next = {rx, data_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                if (b_tick) begin
                    if ((b_tick_cnt_reg == 23) || ((b_tick_cnt_reg > 16) && (!rx))) begin
                        rx_done_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase



    end


endmodule

module uart_tx_top (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx
);

    wire w_b_tick;

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .o_b_tick(w_b_tick)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .b_tick(w_b_tick),
        .tx_busy(tx_busy),
        .tx(tx)
    );


endmodule

// module uart_tx_v2 (
//     input        clk,
//     input        rst,
//     input        tx_start,
//     input  [7:0] tx_data,
//     input        b_tick,
//     output       tx
// );

//     parameter IDLE = 0, WAIT = 1, START = 2, DATA_TR = 3, STOP = 4;

//     reg [3:0] c_state, n_state;
//     reg tx_reg, tx_next;
//     //tx data register
//     reg [7:0] data_reg, data_next;
//     reg [2:0] bit_count_reg, bit_count_next;


//     assign tx = tx_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state <= IDLE;
//             tx_reg <= 1'b1;
//             data_reg <= 8'b0;
//             bit_count_reg <= 3'b0;
//         end else begin
//             c_state <= n_state;
//             tx_reg <= tx_next;
//             data_reg <= data_next;
//             bit_count_reg <= bit_count_next;
//         end
//     end

//     //next state CL, output
//     always @(*) begin
//         n_state = c_state;
//         tx_next = tx_reg;
//         data_next = data_reg;
//         bit_count_next = bit_count_reg;
//         case (c_state)
//             IDLE: begin
//                 tx_next = 1'b1;
//                 if (tx_start) begin
//                     n_state   = WAIT;
//                     data_next = tx_data;
//                 end
//             end
//             WAIT: begin
//                 if (b_tick) n_state = START;
//             end
//             START: begin
//                 tx_next   = 1'b0;
//                 data_next = tx_data;
//                 if (b_tick) n_state = DATA_TR;
//             end
//             DATA_TR: begin
//                 tx_next = data_reg[bit_count_reg];
//                 if (b_tick) begin
//                     if (bit_count_next == 3'd7) begin
//                         bit_count_next = 3'd0;
//                         n_state = STOP;
//                     end else bit_count_next = bit_count_reg + 1'b1;
//                 end
//             end
//             STOP: begin
//                 tx_next = 1'b1;
//                 if (b_tick) n_state = IDLE;
//             end
//         endcase

//     end




// endmodule

// module uart_tx_v1 (
//     input        clk,
//     input        rst,
//     input        tx_start,
//     input  [7:0] tx_data,
//     input        b_tick,
//     output       tx
// );

//     parameter   IDLE = 0,
//                 WAIT = 1,
//                 START = 2,
//                 BIT0 = 3,
//                 BIT1 = 4,
//                 BIT2 = 5,
//                 BIT3 = 6,
//                 BIT4 = 7,
//                 BIT5 = 8,
//                 BIT6 = 9,
//                 BIT7 = 10,
//                 STOP = 11;

//     reg [3:0] c_state, n_state;
//     reg tx_reg, tx_next;
//     //tx data register
//     reg [7:0] data_reg, data_next;
//     reg [2:0] bit_count_reg, bit_count_next;


//     assign tx = tx_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state  <= IDLE;
//             tx_reg   <= 1'b1;
//             data_reg <= 8'b0;
//         end else begin
//             c_state  <= n_state;
//             tx_reg   <= tx_next;
//             data_reg <= data_next;
//         end
//     end

//     //next state CL, output
//     always @(*) begin
//         n_state   = c_state;
//         tx_next   = tx_reg;
//         data_next = data_reg;
//         case (c_state)
//             IDLE: begin
//                 tx_next = 1'b1;
//                 if (tx_start) begin
//                     n_state   = WAIT;
//                     data_next = tx_data;
//                 end
//             end
//             WAIT: begin
//                 if (b_tick) n_state = START;
//             end
//             START: begin
//                 tx_next = 1'b0;
//                 if (b_tick) n_state = BIT0;
//             end
//             BIT0: begin
//                 tx_next = data_reg[0];
//                 if (b_tick) n_state = BIT1;
//             end
//             BIT1: begin
//                 tx_next = data_reg[1];
//                 if (b_tick) n_state = BIT2;
//             end
//             BIT2: begin
//                 tx_next = data_reg[2];
//                 if (b_tick) n_state = BIT3;
//             end
//             BIT3: begin
//                 tx_next = data_reg[3];
//                 if (b_tick) n_state = BIT4;
//             end
//             BIT4: begin
//                 tx_next = data_reg[4];
//                 if (b_tick) n_state = BIT5;
//             end
//             BIT5: begin
//                 tx_next = data_reg[5];
//                 if (b_tick) n_state = BIT6;
//             end
//             BIT6: begin
//                 tx_next = data_reg[6];
//                 if (b_tick) n_state = BIT7;
//             end
//             BIT7: begin
//                 tx_next = data_reg[7];
//                 if (b_tick) n_state = STOP;
//             end
//             STOP: begin
//                 tx_next = 1'b0;
//                 if (b_tick) n_state = IDLE;
//             end
//         endcase


//     end




// endmodule

module baud_tick_gen #(
    TICK_HZ = 9600 * 16  // bps
) (
    input      clk,
    input      rst,
    output reg o_b_tick
);


    parameter F_COUNT = 100_000_000 / TICK_HZ;
    parameter WIDTH = $clog2(F_COUNT) - 1;


    reg [WIDTH : 0] counter;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_b_tick <= 1'b0;
            counter  <= 0;
        end else begin
            if (counter == F_COUNT - 1) begin
                counter  <= 0;
                o_b_tick <= 1'b1;
            end else begin
                counter  <= counter + 1;
                o_b_tick <= 1'b0;
            end
        end
    end


endmodule


module baud_tick_gen_edit #(
    TICK_HZ = 9600 * 16  // bps
) (
    input      clk,
    input      rst,
    output reg o_b_tick
);


    parameter F_COUNT = 100_000_000 / TICK_HZ;
    parameter WIDTH = $clog2(F_COUNT) - 1;
    parameter B_COUNT = 15625;
    parameter B_COUNT_WIDTH = $clog2(B_COUNT) - 1;

    reg [WIDTH : 0] counter;
    reg [B_COUNT_WIDTH : 0] b_tick_cnt;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_b_tick <= 1'b0;
            counter <= 0;
            b_tick_cnt <= 0;
        end else begin
            if (counter == F_COUNT - 1) begin
                counter <= 0;
                if (b_tick_cnt == B_COUNT - 1) begin
                    b_tick_cnt <= 0;
                    o_b_tick   <= 1'b0;
                end else begin
                    o_b_tick   <= 1'b1;
                    b_tick_cnt <= b_tick_cnt + 1;
                end
            end else begin
                counter  <= counter + 1;
                o_b_tick <= 1'b0;
            end
        end
    end


endmodule
